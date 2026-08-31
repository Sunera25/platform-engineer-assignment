# ADR 0001 — ECS Hosting Model: EC2 vs. Fargate

**Date:** 2026-08-31
**Status:** Accepted

---

## Context

TaskFlow must run as a containerised workload on AWS ECS. ECS supports two launch types:

- **Fargate** — AWS manages the underlying compute; operators specify only CPU and memory per task. No EC2 instances are visible or accessible.
- **EC2 (ECS on EC2)** — operators provision and manage an Auto Scaling Group of ECS-optimised EC2 instances. The ECS agent runs on each host and places containers onto them.

The assignment also requires Ansible to perform configuration management on the compute layer (installing Docker, the CloudWatch agent, hardening the OS, and tuning ECS agent settings). Ansible operates over SSH against real host instances.

A secondary requirement is a **vertical scaling mechanism** driven by CloudWatch alarms — a Lambda function that registers a new ECS task definition with higher CPU/memory and forces a redeployment. On Fargate, vertical scaling is straightforward because the task definition alone determines the compute allocation. On EC2, the task definition's resource requirements must fit within the registered capacity of the host instances.

---

## Decision

**Use ECS on EC2 (not Fargate).**

Rationale:

1. **Ansible requires SSH-accessible hosts.** Fargate tasks run in an AWS-managed micro-VM with no persistent, reachable host. There is no EC2 instance to target with an Ansible inventory. ECS on EC2 gives us real instances tagged with `Project=taskflow` and `Environment=prod` that the `aws_ec2` dynamic inventory plugin discovers and Ansible connects to over SSH.

2. **The assignment explicitly tests the IaC/config-management split.** The spec states: _"ECS cluster on EC2 (Auto Scaling Group of ECS-optimised instances) — explicitly not Fargate, because Ansible needs real hosts to configure."_ Fargate would satisfy containerisation but would leave the Ansible layer with nothing to do, which defeats the purpose of the exercise.

3. **ECS agent configuration is a first-class concern.** The Ansible `ecs-agent` role writes `/etc/ecs/ecs.config` to tune logging, reserving resources, and cluster membership. This is a host-level concern with no equivalent on Fargate.

4. **Vertical scaling complexity is an acceptable trade-off.** On Fargate, a vertically scaled task definition is always placeable as long as the new CPU/memory is within Fargate's supported combinations. On EC2, the host's registered memory caps the maximum task size. For this deployment (t3.micro, ~940 MiB registered), the vertical scaling Lambda is capped at 768 MiB to ensure tasks remain schedulable. In a production environment, the instance type would be sized to the expected maximum vertical scale step.

---

## Consequences

**Positive:**
- Ansible can perform full OS-level configuration management (security updates, SSH hardening, firewall rules, CloudWatch agent, ECS agent tuning).
- The deployment architecture maps directly to the assignment spec.
- EC2 instances are visible in the AWS Console, enabling direct SSH debugging and CloudWatch agent metric collection from the host.

**Negative / mitigations:**
- Operators must manage EC2 instance lifecycle (patches, AMI refreshes). Mitigation: automated security updates via `yum-cron`/`dnf-automatic` (applied by Ansible).
- ECS task placement can fail if host memory is exhausted. Mitigation: `minimumHealthyPercent=0` / `maximumPercent=100` ensures drain-before-place rolling updates; desired count of 1 avoids contention on t3.micro instances.
- Vertical scaling is bounded by host capacity. Mitigation: Lambda caps at 768 MiB; instance type can be upgraded in Terraform if larger task sizes are needed.
- No per-task network isolation (bridge mode shares the host network namespace with port mapping). Mitigation: security groups restrict inbound traffic to ALB only; ECS task role follows least-privilege.

---

## Alternatives Considered

| Option | Reason Rejected |
|---|---|
| Fargate | No real EC2 hosts for Ansible to configure; fails the assignment requirement |
| ECS on EC2 + awsvpc networking | awsvpc requires ENI attachment per task, which exhausts t3.micro's 2-ENI limit; bridge mode is appropriate for this instance type |
| EKS (Kubernetes) | Significant operational overhead; out of scope for this assignment |
| App Runner / Lambda | Not ECS; incompatible with Ansible + ECS agent configuration requirement |
