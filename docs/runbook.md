# TaskFlow Operational Runbook

> Written for on-call engineers who have never seen this system. Follow every step exactly.

---

## System Overview

TaskFlow is a Spring Boot REST API backed by PostgreSQL (RDS). It runs as an ECS service on EC2 instances in a private subnet, fronted by an Application Load Balancer. The deployment region is `us-east-1`.

**Key resource names**

| Resource | Value |
|---|---|
| ECS Cluster | `prod-taskflow-cluster` |
| ECS Service | `prod-taskflow-service` |
| ALB DNS | `prod-taskflow-alb-1535607476.us-east-1.elb.amazonaws.com` |
| ECR Repository | `225076308692.dkr.ecr.us-east-1.amazonaws.com/prod-taskflow` |
| RDS Identifier | `prod-taskflow` |
| CloudWatch Log Group | `/ecs/prod-taskflow` |
| Secrets Manager Secret | `prod-taskflow-db-credentials` |

---

## 1. Deployment Procedure

### 1.1 Standard deployment (via CI/CD pipeline)

Every push to `main` triggers the GitLab pipeline automatically. The pipeline runs:
`lint → security → test → build → plan → [manual: apply] → configure → deploy → smoke-test`

The `apply` stage requires a manual click in GitLab CI. Only click **Apply** when:
- All earlier stages are green.
- The `plan` artifact has been reviewed and no unexpected resource changes appear.

After `apply` completes, the `deploy` stage runs `aws ecs update-service --force-new-deployment`. The `smoke-test` stage then polls `/health` via the ALB for up to 7.5 minutes. A green smoke-test means the deployment is complete.

### 1.2 Emergency manual deployment

Use this only if the pipeline is unavailable.

```bash
# 1. Get the current task definition family and latest revision
aws ecs describe-services \
  --cluster prod-taskflow-cluster \
  --services prod-taskflow-service \
  --query 'services[0].taskDefinition'

# 2. Force a redeployment of the current task definition
aws ecs update-service \
  --cluster prod-taskflow-cluster \
  --service prod-taskflow-service \
  --force-new-deployment \
  --region us-east-1

# 3. Watch the service events until running count reaches 1
aws ecs describe-services \
  --cluster prod-taskflow-cluster \
  --services prod-taskflow-service \
  --query 'services[0].{running:runningCount,events:events[0:3]}'
```

### 1.3 Rollback procedure

```bash
# 1. Find the last known-good task definition revision
aws ecs list-task-definitions \
  --family-prefix prod-taskflow \
  --sort DESC \
  --query 'taskDefinitionArns[0:10]'

# 2. Update the service to the previous revision (replace REV with the revision number)
aws ecs update-service \
  --cluster prod-taskflow-cluster \
  --service prod-taskflow-service \
  --task-definition prod-taskflow:REV \
  --force-new-deployment \
  --region us-east-1

# 3. Verify health via ALB
curl -f http://prod-taskflow-alb-1535607476.us-east-1.elb.amazonaws.com/health
```

---

## 2. Scaling Procedures

### 2.1 Automated vertical scaling (CPU/memory)

A CloudWatch alarm fires when ECS CPU or memory utilisation exceeds the threshold for a sustained period. The alarm invokes a Lambda function (`prod-taskflow-vertical-scaler`) that:
1. Reads the current task definition's CPU and memory.
2. Doubles both values (capped at CPU=1024, memory=768 MiB for t3.micro fleets).
3. Registers a new task definition revision with the higher values.
4. Calls `update-service --force-new-deployment` to roll out the scaled task.

**To check whether a scaling event occurred:**

```bash
aws cloudwatch describe-alarm-history \
  --alarm-name "prod-taskflow-cpu-high" \
  --history-item-type "Action" \
  --query 'AlarmHistoryItems[0:5]'

# Check Lambda logs for the scaling function
aws logs tail /aws/lambda/prod-taskflow-vertical-scaler --since 1h
```

**To intervene if vertical scaling misbehaves:**

If the Lambda scaled memory beyond what the instance can accommodate (memory > 940 MiB on t3.micro), tasks will fail to place. Fix:

```bash
# Register a corrected task definition with memory=512
aws ecs describe-task-definition \
  --task-definition prod-taskflow \
  --query 'taskDefinition' > /tmp/current-td.json

# Edit /tmp/current-td.json to set "memory": 512 in containerDefinitions
# Then register and deploy:
aws ecs register-task-definition --cli-input-json file:///tmp/current-td.json
aws ecs update-service \
  --cluster prod-taskflow-cluster \
  --service prod-taskflow-service \
  --task-definition prod-taskflow:NEW_REV \
  --force-new-deployment
```

**To suppress the alarm temporarily:**

```bash
aws cloudwatch set-alarm-state \
  --alarm-name "prod-taskflow-cpu-high" \
  --state-value OK \
  --state-reason "Manual suppression during incident investigation"
```

### 2.2 Horizontal scaling (task count)

ECS Service Auto Scaling adjusts the desired task count based on CPU target tracking (target: 60% CPU). This is separate from vertical scaling. Horizontal scaling increases task count when load is high; vertical scaling increases per-task resources.

**When to use vertical vs. horizontal scaling:**
- **Vertical**: the application is CPU/memory bound for a single request (e.g., large report generation, heavy computation per task). One fat task is more efficient than many small ones.
- **Horizontal**: the application handles many concurrent requests and each request is fast. More tasks = more parallelism = lower latency under load.

**To view current horizontal scaling state:**

```bash
aws application-autoscaling describe-scaling-activities \
  --service-namespace ecs \
  --resource-id service/prod-taskflow-cluster/prod-taskflow-service \
  --query 'ScalingActivities[0:5]'
```

---

## 3. Incident Scenarios

### 3.1 ECS tasks stuck in PENDING

**Symptoms:** `aws ecs describe-services` shows `runningCount=0`, `pendingCount=1`, events contain "unable to place a task."

**Diagnosis:**

```bash
# 1. Check service events
aws ecs describe-services \
  --cluster prod-taskflow-cluster \
  --services prod-taskflow-service \
  --query 'services[0].events[0:5]'

# 2. Check container instance memory
aws ecs list-container-instances --cluster prod-taskflow-cluster
aws ecs describe-container-instances \
  --cluster prod-taskflow-cluster \
  --container-instances $(aws ecs list-container-instances \
    --cluster prod-taskflow-cluster \
    --query 'containerInstanceArns' --output text) \
  --query 'containerInstances[*].{ec2:ec2InstanceId,remaining_mem:remainingResources[?name==`MEMORY`].integerValue|[0],status:status,agent:agentConnected}'

# 3. Check current task definition memory requirement
aws ecs describe-task-definition \
  --task-definition prod-taskflow \
  --query 'taskDefinition.containerDefinitions[0].memory'
```

**Common causes and fixes:**

| Cause | Fix |
|---|---|
| Task memory > instance remaining memory | Vertical scaling Lambda scaled beyond instance capacity. Register a new task def with `memory=512`, update service. |
| ECS agent disconnected | SSH into the instance, run `sudo systemctl restart ecs`. |
| Secrets Manager permission denied | Check ECS task execution role has `secretsmanager:GetSecretValue` on the secret ARN. |
| ECR image pull failure | Verify the image tag exists in ECR: `aws ecr describe-images --repository-name prod-taskflow`. Check task execution role has ECR read permissions. |
| No container instances registered | ASG instances may not have joined the cluster. Check `/etc/ecs/ecs.config` on the instance has the correct cluster name. |

---

### 3.2 ALB returning 502 Bad Gateway

**Symptoms:** Requests to the ALB return HTTP 502. The service may show `runningCount=1` but the target group shows unhealthy targets.

**Diagnosis:**

```bash
# 1. Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names prod-taskflow-tg \
    --query 'TargetGroups[0].TargetGroupArn' --output text) \
  --query 'TargetHealthDescriptions[*].{target:Target,health:TargetHealth}'

# 2. Check application logs for startup errors
aws logs tail /ecs/prod-taskflow --since 10m --format short

# 3. Check container health in the running task
aws ecs describe-tasks \
  --cluster prod-taskflow-cluster \
  --tasks $(aws ecs list-tasks --cluster prod-taskflow-cluster --query 'taskArns[0]' --output text) \
  --query 'tasks[0].containers[0].{status:lastStatus,health:healthStatus,reason:reason}'
```

**Common causes and fixes:**

| Cause | Fix |
|---|---|
| Spring Boot still starting up (ALB health check failing during startup) | Wait for `health_check_grace_period_seconds` (180s) to expire. Check `startPeriod` in container health check. |
| Application crashed after start | Check CloudWatch logs for stack traces. Roll back to previous task definition revision. |
| Port mapping mismatch | Verify ALB target group port matches `containerPort` in task definition (should be 8080). |
| Database connection failure at startup | Check DB credentials in Secrets Manager are correct. Verify RDS security group allows port 5432 from ECS security group. Check `DB_HOST` env var points to the correct RDS endpoint. |
| Security group blocking ALB-to-task traffic | ECS host security group must allow inbound port 8080 from the ALB security group. |

---

### 3.3 Database connection pool exhaustion

**Symptoms:** Application logs contain `HikariPool-1 - Connection is not available, request timed out after 30000ms`. API responses return HTTP 500 with "Unable to acquire JDBC Connection".

**Diagnosis:**

```bash
# 1. Check current active connections on RDS
# Connect to the RDS instance via a bastion or from an ECS task
# SELECT count(*), state FROM pg_stat_activity GROUP BY state;

# 2. Check application connection pool metrics in CloudWatch logs
aws logs filter-log-events \
  --log-group-name /ecs/prod-taskflow \
  --filter-pattern "HikariPool" \
  --start-time $(date -d '30 minutes ago' +%s)000

# 3. Check RDS max_connections parameter
aws rds describe-db-parameters \
  --db-parameter-group-name $(aws rds describe-db-instances \
    --db-instance-identifier prod-taskflow \
    --query 'DBInstances[0].DBParameterGroups[0].DBParameterGroupName' --output text) \
  --query 'Parameters[?ParameterName==`max_connections`]'
```

**Common causes and fixes:**

| Cause | Fix |
|---|---|
| Too many ECS tasks sharing pool against small RDS | Reduce `spring.datasource.hikari.maximum-pool-size` (default 10) via environment variable. For t3.micro RDS, keep pool per task ≤ 5. |
| Long-running queries holding connections | Identify with `SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE state != 'idle' ORDER BY duration DESC;`. Terminate with `SELECT pg_terminate_backend(pid)`. |
| Connection leaks | Check logs for missed `close()` calls. Reduce `spring.datasource.hikari.connection-timeout` to surface leaks faster. |
| Horizontal scale-out without pool tuning | Each new ECS task opens a full pool. Adjust `maximum-pool-size` inversely to expected task count. |

**Immediate mitigation (without deploying a code change):**

```bash
# Restart the ECS service to flush all connections
aws ecs update-service \
  --cluster prod-taskflow-cluster \
  --service prod-taskflow-service \
  --force-new-deployment \
  --region us-east-1
```

---

## 4. RDS Backup and Restore

### 4.1 Manual snapshot

```bash
aws rds create-db-snapshot \
  --db-instance-identifier prod-taskflow \
  --db-snapshot-identifier prod-taskflow-manual-$(date +%Y%m%d-%H%M) \
  --region us-east-1

# Wait for snapshot to complete
aws rds wait db-snapshot-completed \
  --db-snapshot-identifier prod-taskflow-manual-$(date +%Y%m%d)
```

### 4.2 Restore from snapshot

```bash
# 1. List available snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier prod-taskflow \
  --query 'DBSnapshots[*].{id:DBSnapshotIdentifier,time:SnapshotCreateTime,status:Status}' \
  --output table

# 2. Restore to a new instance from a snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier prod-taskflow-restored \
  --db-snapshot-identifier SNAPSHOT_ID \
  --db-instance-class db.t3.micro \
  --no-multi-az \
  --region us-east-1

# 3. Update the ECS task definition's DB_HOST to point to the restored instance endpoint
# Get the new endpoint:
aws rds describe-db-instances \
  --db-instance-identifier prod-taskflow-restored \
  --query 'DBInstances[0].Endpoint.Address'

# 4. Register a new task definition revision with updated DB_HOST
# (Update terraform/envs/prod/variables.tf db_host default or pass as variable)
# Then run terraform apply or manually register and update the service.
```

### 4.3 Automated backups

RDS automated backups are enabled with a retention period configured in Terraform. Point-in-time recovery (PITR) is available for any point within the retention window:

```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier prod-taskflow \
  --target-db-instance-identifier prod-taskflow-pitr \
  --restore-time 2026-08-31T12:00:00Z \
  --db-instance-class db.t3.micro \
  --region us-east-1
```
