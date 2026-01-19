# Factory Floor Infrastructure

Terraform modules for secure, auto-deployed infrastructure.

## Architecture

```
Internet
    ↓
┌─────────────────────────────────────────────────┐
│           Google HTTPS Load Balancer            │
│           (Cloud Armor attached)                │
├─────────────────────────────────────────────────┤
│  • DDoS protection                              │
│  • Bot blocking (GPTBot, CCBot, etc.)           │
│  • Rate limiting (100 req/min)                  │
│  • OWASP rules (SQLi, XSS, RCE, LFI)           │
└─────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────┐
│              Cloud Run Service                  │
│           (Internal + LB only)                  │
├─────────────────────────────────────────────────┤
│  • No direct internet access                    │
│  • VPC connector for private resources          │
│  • Secrets via Secret Manager                   │
│  • Auto-scaling 0-10 instances                  │
└─────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────┐
│              Supabase / GCS                     │
│           (Data layer)                          │
└─────────────────────────────────────────────────┘
```

## Directory Structure

```
infra/
├── global/              # One-time global setup
│   ├── main.tf          # Cloud Armor, IAM, VPC, Cloud Tasks
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── modules/
│   └── project/         # Per-app module
│       ├── main.tf      # Cloud Run + Load Balancer
│       ├── variables.tf
│       └── outputs.tf
│
└── README.md
```

## Setup (One-Time)

### 1. Prerequisites

```bash
# Install gcloud CLI
brew install google-cloud-sdk

# Authenticate
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

### 2. Deploy Global Infrastructure

```bash
cd infra/global

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GCP project ID

# Initialize
terraform init

# Preview
terraform plan

# Apply
terraform apply
```

This creates:
- Cloud Armor policy (bot blocking, rate limiting, OWASP)
- Cloud Run service account
- VPC + connector
- Cloud Tasks queue
- Secret Manager secrets

### 3. Add Secrets

```bash
# After terraform apply, add secret values:
echo -n "your-sentry-dsn" | gcloud secrets versions add sentry-dsn --data-file=-
echo -n "your-mixpanel-token" | gcloud secrets versions add mixpanel-token --data-file=-
echo -n "your-supabase-service-key" | gcloud secrets versions add supabase-service-key --data-file=-
```

## Per-Project Deployment

### Option A: Via /new-app (Automated)

```
/new-app my-cool-app
```

This will:
1. Create GitHub repo
2. Create Vercel project
3. Create Supabase project
4. Run Terraform to create Cloud Run + LB
5. Wire all secrets
6. Deploy initial code

### Option B: Manual Terraform

```bash
# Create project config
mkdir -p infra/projects/my-app
cd infra/projects/my-app

# Create main.tf
cat > main.tf << 'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}

data "terraform_remote_state" "global" {
  backend = "local"
  config = {
    path = "../../global/terraform.tfstate"
  }
}

module "app" {
  source = "../../modules/project"

  app_name                        = "my-app"
  gcp_project_id                  = "your-project-id"
  cloud_armor_policy_name         = data.terraform_remote_state.global.outputs.cloud_armor_policy_name
  cloud_run_service_account_email = data.terraform_remote_state.global.outputs.cloud_run_service_account_email
  vpc_connector_id                = data.terraform_remote_state.global.outputs.vpc_connector_id
}

output "load_balancer_ip" {
  value = module.app.load_balancer_ip
}
EOF

terraform init
terraform apply
```

## Security Checklist

- [x] Cloud Armor attached to all backends
- [x] Cloud Run set to internal + LB only
- [x] Bot User-Agents blocked
- [x] Rate limiting enabled
- [x] OWASP rules active
- [x] Secrets in Secret Manager (not env vars)
- [x] Service account with least privilege
- [x] VPC connector for private access

## Cost Estimate

| Resource | Cost |
|----------|------|
| Cloud Armor | ~$5/month |
| Load Balancer | ~$18/month |
| Cloud Run | Pay per use |
| VPC Connector | ~$7/month |
| **Total Fixed** | **~$30/month** |

Cloud Run scales to zero, so you only pay for traffic.

## Rollback

```bash
# Destroy per-project resources
cd infra/projects/my-app
terraform destroy

# Destroy global (careful!)
cd infra/global
terraform destroy
```

## Troubleshooting

### Cloud Run not accessible
- Check ingress setting is `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`
- Verify Load Balancer backend is healthy
- Check Cloud Armor logs for blocked requests

### Secrets not loading
- Verify service account has `roles/secretmanager.secretAccessor`
- Check secret version exists: `gcloud secrets versions list SECRET_NAME`

### Rate limited
- Check Cloud Armor logs
- Adjust rate limit threshold in `global/main.tf`
