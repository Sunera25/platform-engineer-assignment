# TaskFlow — Platform Engineering Assignment

A task management REST API built with Spring Boot and PostgreSQL, deployed on AWS ECS (EC2 launch type) with a full CI/CD pipeline, infrastructure as code, and configuration management.

---

## DevOps vs. Platform Engineering

DevOps is about breaking down the wall between development and operations so the same team builds and runs the software. A DevOps team owns everything for their service — the code, the pipeline, the on-call rotation.

Platform Engineering is what happens when you have a lot of teams each doing DevOps and they all keep solving the same problems. Every team ends up writing similar Terraform, setting up the same CloudWatch alarms, and figuring out the same ECS patterns independently. A platform team builds those shared tools and patterns once, and other teams just consume them. The key difference is who the customer is — a platform engineer's customer is other developers, not end users.

This project is built end-to-end like a DevOps project (one service, one team), but it uses platform-style patterns — reusable Terraform modules, an Ansible role, a pipeline with security gates — that would form the foundation for a larger internal developer platform.

---

## DevSecOps

The traditional approach was to have a security team review everything near the end before release. That doesn't scale when you're shipping multiple times a day.

DevSecOps moves security checks into the pipeline so they run automatically on every commit, not after it:

- **Checkov** scans the Terraform for IAM misconfigurations and insecure resource configs before they're ever applied
- **Trivy** scans the container image for known CVEs before it's pushed to ECR
- **Gitleaks** checks for accidentally committed secrets
- Secrets are never in source code or environment files — they're stored in AWS Secrets Manager and injected into ECS tasks at runtime

If a check fails, the pipeline fails. Nothing insecure makes it through without someone explicitly fixing it first. Catching a problem in CI is much cheaper than finding it in production.

---

## Local Setup

### Prerequisites

- Java 17, Maven 3.9+
- Docker
- PostgreSQL (or run one in Docker)

### Run the application

```bash
# Start PostgreSQL
docker run -d \
  --name taskflow-pg \
  -e POSTGRES_DB=taskflow \
  -e POSTGRES_USER=taskflow_admin \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  postgres:15-alpine

# Run the app
cd app
mvn spring-boot:run
```

API: `http://localhost:8080` — Swagger UI: `http://localhost:8080/swagger-ui.html`

### Run tests

```bash
cd app
mvn verify
```

This runs unit tests, integration tests (Testcontainers spins up a real Postgres), and the JaCoCo coverage gate.

### Build the Docker image

```bash
docker build -t taskflow:local app/
docker run -p 8080:8080 \
  -e DB_HOST=host.docker.internal \
  -e DB_NAME=taskflow \
  -e DB_USER=taskflow_admin \
  -e DB_PASSWORD=password \
  taskflow:local
```

---

## Deploying from a Clean AWS Account

### Prerequisites

- AWS CLI configured with admin access (needed to bootstrap — permissions are tightened by IAM modules after)
- Terraform 1.7+
- Ansible 2.15+ with `amazon.aws` and `ansible.posix` collections

### Step 1 — Bootstrap remote state

```bash
aws s3api create-bucket \
  --bucket taskflow-terraform-state-<account-id> \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket taskflow-terraform-state-<account-id> \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name taskflow-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Update `terraform/envs/prod/backend.tf` with the actual bucket name.

### Step 2 — Provision infrastructure

```bash
cd terraform/envs/prod
terraform init
terraform plan -var="image_tag=initial"
terraform apply -var="image_tag=initial"
```

This creates the VPC, subnets, NAT gateway, ALB, ECS cluster, RDS, ECR, IAM roles, and the vertical scaling Lambda.

### Step 3 — Configure EC2 hosts

```bash
cd ansible
pip install ansible boto3 botocore
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
```

The dynamic inventory finds the ECS hosts by their `Project=taskflow` and `Environment=prod` tags.

### Step 4 — Build and push the image

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

IMAGE_TAG=$(git rev-parse --short HEAD)
docker build -t <account-id>.dkr.ecr.us-east-1.amazonaws.com/prod-taskflow:$IMAGE_TAG app/
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/prod-taskflow:$IMAGE_TAG
```

### Step 5 — Deploy

```bash
cd terraform/envs/prod
terraform apply -var="image_tag=$IMAGE_TAG"

aws ecs update-service \
  --cluster prod-taskflow-cluster \
  --service prod-taskflow-service \
  --force-new-deployment \
  --region us-east-1
```

### Step 6 — Verify

```bash
curl http://$(terraform output -raw alb_dns_name)/health
# Expected: {"status":"UP"}
```

### GitLab CI/CD variables required

| Variable | Description |
|----------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM access key for CI |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key |
| `AWS_DEFAULT_REGION` | `us-east-1` |
| `ECR_REGISTRY` | `<account-id>.dkr.ecr.us-east-1.amazonaws.com` |
| `ECR_REPOSITORY` | `prod-taskflow` |
| `ECS_CLUSTER_NAME` | `prod-taskflow-cluster` |
| `ALB_DNS_NAME` | from `terraform output alb_dns_name` |

---

## API Reference

Full spec: [`app/openapi.yaml`](app/openapi.yaml)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| GET | `/api/tasks` | List all tasks |
| POST | `/api/tasks` | Create a task |
| GET | `/api/tasks/{id}` | Get a task by ID |
| PUT | `/api/tasks/{id}` | Update a task |
| DELETE | `/api/tasks/{id}` | Delete a task |
