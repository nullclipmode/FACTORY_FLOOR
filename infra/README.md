# Factory Floor Infrastructure

Terraform modules for secure, auto-deployed infrastructure.

## Architecture

```
Internet
    ↓
┌─────────────────────────────────────────────────┐
│      SHARED Google HTTPS Load Balancer          │
│           (Cloud Armor attached)                │
├─────────────────────────────────────────────────┤
│  • DDoS protection                              │
│  • Bot blocking (GPTBot, CCBot, etc.)           │
│  • Rate limiting (100 req/min)                  │
│  • OWASP rules (SQLi, XSS, RCE, LFI)           │
└─────────────────────────────────────────────────┘
    ↓                    ↓                    ↓
┌──────────┐      ┌──────────┐      ┌──────────┐
│ Backend  │      │ Backend  │      │ Backend  │
│  App 1   │      │  App 2   │      │  App N   │
└──────────┘      └──────────┘      └──────────┘
    ↓                    ↓                    ↓
┌─────────────────────────────────────────────────┐
│              Cloud Run Services                 │
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

**Key Architecture Points:**
- One GCP project for everything
- One shared HTTPS Load Balancer (not per-app)
- Cloud Armor attaches to the shared Load Balancer
- Each app = separate Cloud Run service + backend on shared LB
- Global infra deployed once, apps add their backends

## Directory Structure

```
infra/
├── global/              # One-time global setup
│   ├── main.tf          # Cloud Armor, IAM, VPC, Cloud Tasks, SHARED LB
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── modules/
│   └── project/         # Per-app module
│       ├── main.tf      # Cloud Run + Backend (on shared LB)
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
- **Shared HTTPS Load Balancer** (with Cloud Armor attached)
- HTTP → HTTPS redirect
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

### 4. Note Load Balancer IP

After `terraform apply`, note the shared Load Balancer IP:

```bash
terraform output load_balancer_ip
```

All your apps will be accessible via this single IP (via path-based routing).

## Per-App Deployment

### Option A: Via /new-app (Automated)

```
/new-app my-cool-app
```

This will:
1. Create GitHub repo
2. Create Vercel project
3. Create Supabase project
4. Run Terraform to create Cloud Run + backend on shared LB
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
  url_map_name                    = data.terraform_remote_state.global.outputs.url_map_name
  cloud_run_service_account_email = data.terraform_remote_state.global.outputs.cloud_run_service_account_email
  vpc_connector_id                = data.terraform_remote_state.global.outputs.vpc_connector_id
}

output "backend_service_id" {
  value = module.app.backend_service_id
}
EOF

terraform init
terraform apply
```

After creating the app, you need to add its backend to the shared URL map (path-based routing):

```bash
# Add path rule to shared URL map (manual step or via gcloud)
gcloud compute url-maps add-path-matcher factory-floor-urlmap \
  --path-matcher-name=my-app-matcher \
  --default-service=ff-my-app-backend \
  --path-rules="/my-app/*=ff-my-app-backend"
```

## Security Checklist

- [x] **One shared Load Balancer** for all apps
- [x] Cloud Armor attached to shared LB (protects all apps)
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
| **Load Balancer (shared)** | **~$18/month** |
| Cloud Run (per app) | Pay per use |
| VPC Connector | ~$7/month |
| **Total Fixed** | **~$30/month** |

**Note:** The Load Balancer is a fixed cost shared across ALL apps. Each new app only adds Cloud Run usage costs (pay per request).

## Rollback

```bash
# Destroy per-project resources
cd infra/projects/my-app
terraform destroy

# Destroy global (careful! removes LB for ALL apps)
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

### New app not reachable
- Verify backend was added to shared URL map
- Check path rules: `gcloud compute url-maps describe factory-floor-urlmap`
