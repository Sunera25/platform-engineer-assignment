"""
Captures evidence of a vertical scaling event:
  1. Records the current ECS task definition (before)
  2. Manually sets the CloudWatch CPU alarm to ALARM state
  3. Waits for the Lambda to execute and register a new task definition
  4. Pulls Lambda execution logs
  5. Records the new task definition (after)

Results are written to files/evidence_output/ as JSON files.

Credentials are read from files/keys.json:
  {
    "aws_access_key_id": "AKIA...",
    "aws_secret_access_key": "...",
    "region": "us-east-1"
  }
"""

import json
import os
import time
import boto3
from datetime import datetime, timezone, timedelta
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).parent
KEYS_FILE = SCRIPT_DIR / "keys.json"
OUTPUT_DIR = SCRIPT_DIR / "evidence_output"

CLUSTER = "prod-taskflow-cluster"
SERVICE = "prod-taskflow-service"
TASK_FAMILY = "prod-taskflow"
CPU_ALARM = "prod-taskflow-cpu-utilization-high"
LAMBDA_LOG_GROUP = "/aws/lambda/prod-taskflow-vertical-scaling"
LAMBDA_WAIT_SECONDS = 25


# ── Helpers ───────────────────────────────────────────────────────────────────

def load_credentials():
    with open(KEYS_FILE) as f:
        raw = json.load(f)

    # Support both flat format and AWS CLI 'create-access-key' output format
    if "AccessKey" in raw:
        key = raw["AccessKey"]["AccessKeyId"]
        secret = raw["AccessKey"]["SecretAccessKey"]
        region = raw.get("region", "us-east-1")
    else:
        key = raw["aws_access_key_id"]
        secret = raw["aws_secret_access_key"]
        region = raw.get("region", "us-east-1")

    return {
        "aws_access_key_id": key,
        "aws_secret_access_key": secret,
        "region_name": region,
    }


def make_client(service, creds):
    return boto3.client(service, **creds)


def save(name, data):
    OUTPUT_DIR.mkdir(exist_ok=True)
    path = OUTPUT_DIR / f"{name}.json"
    with open(path, "w") as f:
        json.dump(data, f, indent=2, default=str)
    print(f"  Saved → {path.relative_to(SCRIPT_DIR.parent)}")
    return data


def ts():
    return datetime.now(timezone.utc).strftime("%H:%M:%S UTC")


# ── Steps ─────────────────────────────────────────────────────────────────────

def step_before(ecs):
    print(f"\n[{ts()}] Step 1 — recording current (before) task definition")
    svc = ecs.describe_services(cluster=CLUSTER, services=[SERVICE])["services"][0]
    current_arn = svc["taskDefinition"]
    td = ecs.describe_task_definition(taskDefinition=current_arn)["taskDefinition"]
    before = {
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "service": {
            "cluster": CLUSTER,
            "service": SERVICE,
            "taskDefinition": current_arn,
            "desiredCount": svc["desiredCount"],
            "runningCount": svc["runningCount"],
        },
        "taskDefinition": {
            "family": td["family"],
            "revision": td["revision"],
            "taskDefinitionArn": td["taskDefinitionArn"],
            "cpu": td.get("cpu"),
            "memory": td.get("memory"),
            "containerDefinitions": [
                {
                    "name": c["name"],
                    "cpu": c.get("cpu"),
                    "memory": c.get("memory"),
                }
                for c in td["containerDefinitions"]
            ],
        },
    }
    print(f"  Current task def: {td['family']}:{td['revision']}  "
          f"cpu={td.get('cpu')}  memory={td.get('memory')}")
    save("01_before_task_definition", before)
    return td["revision"]


def step_trigger_alarm(cw):
    print(f"\n[{ts()}] Step 2 — setting '{CPU_ALARM}' → ALARM to trigger Lambda")
    cw.set_alarm_state(
        AlarmName=CPU_ALARM,
        StateValue="ALARM",
        StateReason="Manual trigger for vertical scaling evidence capture",
    )
    print("  Alarm state set to ALARM")


def step_confirm_alarm(cw):
    print(f"\n[{ts()}] Step 3 — confirming alarm state")
    alarms = cw.describe_alarms(AlarmNames=[CPU_ALARM])["MetricAlarms"]
    if not alarms:
        print("  WARNING: alarm not found")
        return {}
    alarm = alarms[0]
    data = {
        "AlarmName": alarm["AlarmName"],
        "StateValue": alarm["StateValue"],
        "StateReason": alarm["StateReason"],
        "StateUpdatedTimestamp": str(alarm["StateUpdatedTimestamp"]),
        "AlarmDescription": alarm.get("AlarmDescription", ""),
        "Threshold": alarm.get("Threshold"),
        "ComparisonOperator": alarm.get("ComparisonOperator"),
    }
    print(f"  State: {data['StateValue']}  updated: {data['StateUpdatedTimestamp']}")
    save("02_cloudwatch_alarm_fired", data)
    return data


def step_wait_for_lambda():
    print(f"\n[{ts()}] Step 4 — waiting {LAMBDA_WAIT_SECONDS}s for Lambda to execute", end="", flush=True)
    for _ in range(LAMBDA_WAIT_SECONDS):
        time.sleep(1)
        print(".", end="", flush=True)
    print(" done")


def step_lambda_logs(logs_client):
    print(f"\n[{ts()}] Step 5 — pulling Lambda execution logs")
    since_ms = int((datetime.now(timezone.utc) - timedelta(minutes=5)).timestamp() * 1000)
    try:
        resp = logs_client.filter_log_events(
            logGroupName=LAMBDA_LOG_GROUP,
            startTime=since_ms,
        )
        events = [
            {"timestamp": e["timestamp"], "message": e["message"].rstrip()}
            for e in resp.get("events", [])
        ]
    except logs_client.exceptions.ResourceNotFoundException:
        print("  WARNING: Lambda log group not found — Lambda may not have run yet")
        events = []

    data = {
        "log_group": LAMBDA_LOG_GROUP,
        "queried_from": datetime.fromtimestamp(since_ms / 1000, tz=timezone.utc).isoformat(),
        "event_count": len(events),
        "events": events,
    }
    print(f"  Found {len(events)} log events")
    for e in events:
        print(f"    {e['message'][:120]}")
    save("03_lambda_execution_logs", data)
    return events


def step_after(ecs, before_revision):
    print(f"\n[{ts()}] Step 6 — recording new (after) task definition")
    # List all revisions and pick the latest
    paginator = ecs.get_paginator("list_task_definitions")
    arns = []
    for page in paginator.paginate(familyPrefix=TASK_FAMILY, sort="DESC"):
        arns.extend(page["taskDefinitionArns"])
        if arns:
            break

    if not arns:
        print("  ERROR: no task definitions found")
        return

    latest_arn = arns[0]
    td = ecs.describe_task_definition(taskDefinition=latest_arn)["taskDefinition"]
    svc = ecs.describe_services(cluster=CLUSTER, services=[SERVICE])["services"][0]

    after = {
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "service": {
            "taskDefinition": svc["taskDefinition"],
            "desiredCount": svc["desiredCount"],
            "runningCount": svc["runningCount"],
            "deployments": [
                {
                    "id": d["id"],
                    "status": d["status"],
                    "taskDefinition": d["taskDefinition"],
                    "runningCount": d["runningCount"],
                    "createdAt": str(d["createdAt"]),
                }
                for d in svc["deployments"]
            ],
        },
        "taskDefinition": {
            "family": td["family"],
            "revision": td["revision"],
            "taskDefinitionArn": td["taskDefinitionArn"],
            "cpu": td.get("cpu"),
            "memory": td.get("memory"),
            "containerDefinitions": [
                {
                    "name": c["name"],
                    "cpu": c.get("cpu"),
                    "memory": c.get("memory"),
                }
                for c in td["containerDefinitions"]
            ],
        },
    }
    print(f"  New task def:     {td['family']}:{td['revision']}  "
          f"cpu={td.get('cpu')}  memory={td.get('memory')}")
    if td["revision"] == before_revision:
        print("  NOTE: revision unchanged — Lambda may still be starting or "
              "the new deployment hasn't been registered yet. "
              "Re-run this script in 30s to re-capture the after state.")
    save("04_after_task_definition", after)


def step_summary(before_revision):
    print(f"\n[{ts()}] Step 7 — writing summary")
    # Load all saved files to build summary
    files = sorted(OUTPUT_DIR.glob("*.json"))
    before_td, after_td = None, None
    alarm_data, lambda_events = None, []

    for f in files:
        data = json.loads(f.read_text())
        if "01_before" in f.name:
            before_td = data["taskDefinition"]
        elif "04_after" in f.name:
            after_td = data["taskDefinition"]
        elif "02_cloudwatch" in f.name:
            alarm_data = data
        elif "03_lambda" in f.name:
            lambda_events = data.get("events", [])

    summary = {
        "evidence_type": "Vertical scaling event",
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "alarm": alarm_data,
        "before": before_td,
        "after": after_td,
        "lambda_log_lines": len(lambda_events),
        "scaling_occurred": (
            after_td is not None
            and before_td is not None
            and after_td["revision"] != before_td["revision"]
        ),
    }
    save("00_summary", summary)

    print("\n" + "=" * 60)
    print("VERTICAL SCALING EVIDENCE SUMMARY")
    print("=" * 60)
    if before_td:
        print(f"  Before: revision={before_td['revision']}  "
              f"cpu={before_td['cpu']}  memory={before_td['memory']}")
    if after_td:
        print(f"  After:  revision={after_td['revision']}  "
              f"cpu={after_td['cpu']}  memory={after_td['memory']}")
    if alarm_data:
        print(f"  Alarm:  {alarm_data['AlarmName']} → {alarm_data['StateValue']} "
              f"at {alarm_data['StateUpdatedTimestamp']}")
    print(f"  Lambda log lines captured: {len(lambda_events)}")
    print(f"  Scaling occurred: {summary['scaling_occurred']}")
    print(f"\n  Output files: {OUTPUT_DIR.relative_to(SCRIPT_DIR.parent)}/")
    print("=" * 60)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("Loading credentials from", KEYS_FILE)
    creds = load_credentials()
    region = creds["region_name"]
    print(f"Region: {region}")

    ecs = make_client("ecs", creds)
    cw = make_client("cloudwatch", creds)
    logs = make_client("logs", creds)

    before_revision = step_before(ecs)
    step_trigger_alarm(cw)
    step_confirm_alarm(cw)
    step_wait_for_lambda()
    step_lambda_logs(logs)
    step_after(ecs, before_revision)
    step_summary(before_revision)


if __name__ == "__main__":
    main()
