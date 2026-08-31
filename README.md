# TaskFlow — Platform Engineering Assignment

A small internal task management REST service built to demonstrate end-to-end platform engineering: application development, containerization, infrastructure as code, configuration management, CI/CD, and observability on AWS.

---

## DevOps vs. Platform Engineering

DevOps emerged as a cultural movement to break down the wall between development and operations. In the classic pre-DevOps world, developers threw software "over the fence" to operations teams, who were responsible for running it. DevOps collapsed that boundary by embedding operations thinking into development teams and automating the repetitive work (testing, building, deploying) that used to require specialist handoffs. A DevOps team typically owns a single product or service from code commit through production operation — they write the application, set up the CI/CD pipeline, manage alerts, and respond to incidents. The scope is deep but narrow.

Platform Engineering is a natural evolution of DevOps at scale. Once an organization has many product teams each doing DevOps, a problem emerges: every team re-invents the same infrastructure patterns — container orchestration, service meshes, secrets management, cost tagging, compliance guardrails. Each team must become an expert in AWS, Kubernetes, Terraform, and a dozen other tools just to run their service. Platform Engineering addresses this by creating a dedicated team (the platform team) that builds and operates a self-service Internal Developer Platform (IDP) that product teams consume. Instead of every team managing ECS task definitions, the platform team provides a golden-path template. Instead of every team wiring their own CloudWatch alarms, the platform team provides a pre-built observability module.

The key distinction is the customer: a DevOps engineer's customer is the end user of the product; a platform engineer's customer is the developer building that product. Platform engineering optimizes for developer experience (DX), cognitive load reduction, and organizational consistency. It treats infrastructure as a product with its own SLOs, documentation, and versioned releases.

This assignment sits at the boundary of both disciplines: it builds one service (DevOps), but does so with the platform engineering tools and practices (Terraform modules, Ansible roles, pipeline templates, runbooks) that would form the foundation of a larger IDP.

---

## The Shift to DevSecOps

Traditional security in software organizations was a gate at the end of the development cycle — a security team reviewed software shortly before release, found issues, and handed back a list of findings. This model is too slow for organizations shipping multiple times a day and incompatible with the continuous delivery that DevOps enabled.

DevSecOps shifts security left — integrating it into every stage of the development lifecycle rather than applying it at the end:

- **In planning:** threat modelling and security requirements defined alongside functional requirements.
- **In development:** static application security testing (SAST) in the IDE, pre-commit hooks that scan for secrets, dependency vulnerability scanning against CVE databases.
- **In CI/CD:** automated security gates (Checkov for infrastructure misconfigurations, Trivy for container CVEs, Gitleaks for accidentally committed credentials) that fail the pipeline before any insecure code can reach production.
- **In deployment:** infrastructure is immutable and versioned; secrets are never in environment files or source code but injected at runtime from a secrets manager.
- **In operations:** runtime threat detection (GuardDuty, CloudTrail alerts), automated patching (yum-cron automatic security updates on EC2 hosts), and least-privilege IAM everywhere.

The `security` stage in this project's `.gitlab-ci.yml` demonstrates DevSecOps: Checkov, Trivy, and Gitleaks run automatically on every commit and merge request. A single critical CVE in the container image or a mismatched IAM policy fails the build before any human reviewer needs to look at it.

DevSecOps matters because the cost of finding a vulnerability in CI is orders of magnitude lower than finding it in production, and because manual security reviews cannot scale to the velocity of modern software delivery.

---

## Local Setup

### Prerequisites

- Java 17, Maven 3.9+
- Docker
- PostgreSQL (or Docker to run one)

### Run the application locally

```bash
# Start PostgreSQL in Docker
docker run -d \
  --name taskflow-pg \
  -e POSTGRES_DB=taskflow \
  -e POSTGRES_USER=taskflow_admin \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  postgres:15-alpine

# Run the Spring Boot app
cd app
mvn spring-boot:run
```

The API is available at `http://localhost:8080`. API documentation is at `http://localhost:8080/swagger-ui.html`.

### Run tests

```bash
cd app
mvn verify   # runs unit tests, integration tests (Testcontainers), and JaCoCo coverage gate
```

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

## Reproducing the Full Deployment from a Clean AWS Account

### Prerequisites

- AWS CLI configured with an IAM user/role that has admin access (to bootstrap; after bootstrap, permissions are scoped by IAM modules).
- Terraform 1.7+ installed.
- Ansible 2.15+ with `amazon.aws` and `ansible.posix` collections.
- GitLab CI/CD variables configured (see below).

### Step 1 — Bootstrap remote state

```bash
# Create S3 bucket for Terraform state (once, manually or via a bootstrap script)
aws s3api create-bucket \
  --bucket taskflow-terraform-state-<account-id> \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket taskflow-terraform-state-<account-id> \
  --versioning-configuration Status=Enabled

# Create DynamoDB lock table
aws dynamodb create-table \
  --table-name taskflow-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Update `terraform/envs/prod/backend.tf` with the actual bucket name and lock table.

### Step 2 — Provision infrastructure

```bash
cd terraform/envs/prod
terraform init
terraform plan -var="image_tag=initial"
terraform apply -var="image_tag=initial"
```

This creates the VPC, subnets, NAT gateway, ALB, ECS cluster (EC2 ASG), RDS instance, ECR repository, IAM roles, CloudWatch log groups, and the vertical scaling Lambda.

### Step 3 — Configure EC2 hosts

```bash
cd ansible
pip install ansible boto3 botocore
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
```

The dynamic inventory picks up instances by the `Project=taskflow` and `Environment=prod` tags.

### Step 4 — Build and push the application image

```bash
# Authenticate to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and push
IMAGE_TAG=$(git rev-parse --short HEAD)
docker build -t <account-id>.dkr.ecr.us-east-1.amazonaws.com/taskflow:$IMAGE_TAG app/
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/taskflow:$IMAGE_TAG
```

### Step 5 — Update task definition and deploy

```bash
# Apply with the real image tag
cd terraform/envs/prod
terraform apply -var="image_tag=$IMAGE_TAG"

# Force new deployment
aws ecs update-service \
  --cluster taskflow-prod \
  --service taskflow-service \
  --force-new-deployment
```

### Step 6 — Verify

```bash
# Get the ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names taskflow-alb \
  --query 'LoadBalancers[0].DNSName' --output text)

curl http://$ALB_DNS/health
# Expected: {"status":"UP"}
```

### GitLab CI/CD variables (masked and protected)

| Variable | Description |
|----------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM access key for CI (use a scoped CI role in production) |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key |
| `AWS_DEFAULT_REGION` | e.g. `us-east-1` |
| `ECR_REGISTRY` | e.g. `<account-id>.dkr.ecr.us-east-1.amazonaws.com` |
| `ECR_REPOSITORY` | `taskflow` |
| `ECS_CLUSTER_NAME` | `taskflow-prod` |
| `ALB_DNS_NAME` | Output from `terraform output alb_dns_name` |

---

## API Reference

Full OpenAPI spec: [`app/openapi.yaml`](app/openapi.yaml)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check (used by ALB and ECS) |
| GET | `/api/tasks` | List all tasks |
| POST | `/api/tasks` | Create a task |
| GET | `/api/tasks/{id}` | Get a task by ID |
| PUT | `/api/tasks/{id}` | Update a task |
| DELETE | `/api/tasks/{id}` | Delete a task |
