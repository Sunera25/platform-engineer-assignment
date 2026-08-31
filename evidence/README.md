# Evidence

This directory contains screenshots and recordings proving the system actually ran end-to-end.

## Contents

| File | What it shows |
|---|---|
| `pipeline-green.png` | Full green pipeline run — all 9 stages visible |
| `terraform-apply.png` | `terraform apply` output showing VPC, ECS cluster, ALB, RDS created |
| `aws-console-resources.png` | AWS Console showing the created resources |
| `ansible-run.png` | First Ansible playbook run |
| `ansible-idempotent.png` | Second Ansible run — zero changes (idempotency proof) |
| `app-via-alb.png` | Application responding via ALB public DNS (`/health` returns 200) |
| `cloudwatch-logs.png` | CloudWatch log stream showing application JSON output |
| `vertical-scaling-alarm.png` | CloudWatch alarm in ALARM state triggering the Lambda |
| `vertical-scaling-before.png` | Task definition before vertical scaling (CPU=256, memory=512) |
| `vertical-scaling-after.png` | Task definition after vertical scaling (CPU=512, memory=768) |

## How to capture evidence for a new run

1. **Pipeline screenshot**: In GitLab CI → Pipelines, find the green run and take a full-page screenshot showing all stages.
2. **Terraform apply**: Copy the `terraform apply` output from the CI job log or terminal session.
3. **AWS Console**: Navigate to VPC, ECS, ALB, RDS and take screenshots showing each resource.
4. **Ansible**: Run `ansible-playbook ansible/site.yml -v` twice and capture both terminal outputs.
5. **ALB health check**: `curl -v http://<ALB_DNS>/health` and screenshot.
6. **CloudWatch logs**: Open `/ecs/prod-taskflow` log group and screenshot a recent log stream.
7. **Vertical scaling**: Use `aws cloudwatch set-alarm-state --state-value ALARM` to trigger the alarm, then screenshot the Lambda execution and the before/after task definition.
