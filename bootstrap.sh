#!/usr/bin/env bash
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
AWS_REGION="us-east-1"
ENVIRONMENT="prod"
TF_STATE_BUCKET="taskflow-terraform-state-$(aws sts get-caller-identity --query Account --output text)"
TF_LOCK_TABLE="taskflow-terraform-locks"
ECR_REPO_NAME="${ENVIRONMENT}-taskflow"
# ──────────────────────────────────────────────────────────────────────────────

echo "Bootstrapping Terraform remote state backend..."
echo "Region : $AWS_REGION"
echo "Bucket : $TF_STATE_BUCKET"
echo "Table  : $TF_LOCK_TABLE"
echo ""

# S3 bucket for Terraform state
if aws s3api head-bucket --bucket "$TF_STATE_BUCKET" 2>/dev/null; then
  echo "[SKIP] S3 bucket already exists: $TF_STATE_BUCKET"
else
  echo "[CREATE] S3 bucket: $TF_STATE_BUCKET"
  if [ "$AWS_REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "$TF_STATE_BUCKET" \
      --region "$AWS_REGION"
  else
    aws s3api create-bucket \
      --bucket "$TF_STATE_BUCKET" \
      --region "$AWS_REGION" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION"
  fi
fi

echo "[CONFIG] Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket "$TF_STATE_BUCKET" \
  --versioning-configuration Status=Enabled

echo "[CONFIG] Enabling server-side encryption..."
aws s3api put-bucket-encryption \
  --bucket "$TF_STATE_BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "[CONFIG] Blocking all public access..."
aws s3api put-public-access-block \
  --bucket "$TF_STATE_BUCKET" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# DynamoDB table for state locking
if aws dynamodb describe-table --table-name "$TF_LOCK_TABLE" --region "$AWS_REGION" 2>/dev/null; then
  echo "[SKIP] DynamoDB table already exists: $TF_LOCK_TABLE"
else
  echo "[CREATE] DynamoDB table: $TF_LOCK_TABLE"
  aws dynamodb create-table \
    --table-name "$TF_LOCK_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION"

  echo "[WAIT] Waiting for DynamoDB table to be active..."
  aws dynamodb wait table-exists \
    --table-name "$TF_LOCK_TABLE" \
    --region "$AWS_REGION"
fi

# ECR repository — must exist before the CI/CD build stage runs
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

if aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" 2>/dev/null; then
  echo "[SKIP] ECR repository already exists: $ECR_REPO_NAME"
else
  echo "[CREATE] ECR repository: $ECR_REPO_NAME"
  aws ecr create-repository \
    --repository-name "$ECR_REPO_NAME" \
    --image-scanning-configuration scanOnPush=true \
    --region "$AWS_REGION"
fi

echo ""
echo "Bootstrap complete."
echo ""
echo "Set these as CI/CD variables in GitLab:"
echo "  ECR_REGISTRY   = $ECR_REGISTRY"
echo "  ECR_REPOSITORY = $ECR_REPO_NAME"
echo ""
echo "Update terraform/envs/prod/backend.tf with:"
echo "  bucket         = \"$TF_STATE_BUCKET\""
echo "  dynamodb_table = \"$TF_LOCK_TABLE\""
echo "  region         = \"$AWS_REGION\""
