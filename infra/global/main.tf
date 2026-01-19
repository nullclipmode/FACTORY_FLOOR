# Factory Floor - Global Infrastructure
# Run once to set up shared resources across all apps
#
# Usage:
#   cd infra/global
#   terraform init
#   terraform plan -var="gcp_project_id=your-project-id"
#   terraform apply -var="gcp_project_id=your-project-id"

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Uncomment to use remote state (recommended)
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "factory-floor/global"
  # }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudtasks.googleapis.com",
    "aiplatform.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "iam.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

# ============================================
# CLOUD ARMOR - Global Security Policy
# ============================================

resource "google_compute_security_policy" "factory_floor" {
  name        = "factory-floor-armor"
  description = "Global Cloud Armor policy for all Factory Floor apps"

  # Default rule - allow
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow rule"
  }

  # Block known bad bots via User-Agent
  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      expr {
        expression = <<-EOT
          request.headers['user-agent'].contains('GPTBot') ||
          request.headers['user-agent'].contains('ChatGPT') ||
          request.headers['user-agent'].contains('CCBot') ||
          request.headers['user-agent'].contains('anthropic-ai') ||
          request.headers['user-agent'].contains('Claude-Web') ||
          request.headers['user-agent'].contains('Bytespider') ||
          request.headers['user-agent'].contains('PetalBot') ||
          request.headers['user-agent'].contains('Scrapy')
        EOT
      }
    }
    description = "Block known AI crawlers and scrapers"
  }

  # Rate limiting - 100 requests per minute per IP
  rule {
    action   = "rate_based_ban"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
      ban_duration_sec = 300
    }
    description = "Rate limit - 100 req/min, ban 5 min"
  }

  # OWASP Top 10 protection (preconfigured rules)
  rule {
    action   = "deny(403)"
    priority = "3000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
    description = "SQL injection protection"
  }

  rule {
    action   = "deny(403)"
    priority = "3001"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
    description = "XSS protection"
  }

  rule {
    action   = "deny(403)"
    priority = "3002"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('rce-v33-stable')"
      }
    }
    description = "Remote code execution protection"
  }

  rule {
    action   = "deny(403)"
    priority = "3003"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('lfi-v33-stable')"
      }
    }
    description = "Local file inclusion protection"
  }

  depends_on = [google_project_service.apis]
}

# ============================================
# IAM - Service Accounts
# ============================================

# Cloud Run service account (shared, least privilege)
resource "google_service_account" "cloud_run" {
  account_id   = "factory-floor-run"
  display_name = "Factory Floor Cloud Run"
  description  = "Service account for Cloud Run services"
}

# Grant Secret Manager access to Cloud Run SA
resource "google_project_iam_member" "cloud_run_secrets" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Grant Cloud Tasks access
resource "google_project_iam_member" "cloud_run_tasks" {
  project = var.gcp_project_id
  role    = "roles/cloudtasks.enqueuer"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Grant Cloud Logging access
resource "google_project_iam_member" "cloud_run_logging" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Grant Vertex AI access
resource "google_project_iam_member" "cloud_run_vertex" {
  project = var.gcp_project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# ============================================
# SECRET MANAGER - Base Structure
# ============================================

# Example: Supabase URL (per-project secrets added by project module)
resource "google_secret_manager_secret" "supabase_service_key" {
  secret_id = "supabase-service-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

# Sentry DSN
resource "google_secret_manager_secret" "sentry_dsn" {
  secret_id = "sentry-dsn"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

# Mixpanel token
resource "google_secret_manager_secret" "mixpanel_token" {
  secret_id = "mixpanel-token"

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

# ============================================
# VPC - Network (optional, for private services)
# ============================================

resource "google_compute_network" "factory_floor" {
  name                    = "factory-floor-vpc"
  auto_create_subnetworks = false

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "factory_floor" {
  name          = "factory-floor-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.factory_floor.id

  # Enable Private Google Access for serverless
  private_ip_google_access = true
}

# VPC Connector for Cloud Run to access private resources
resource "google_vpc_access_connector" "factory_floor" {
  name          = "factory-floor-connector"
  region        = var.gcp_region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.factory_floor.name

  depends_on = [google_project_service.apis]
}

# ============================================
# CLOUD TASKS - Queue
# ============================================

resource "google_cloud_tasks_queue" "default" {
  name     = "factory-floor-tasks"
  location = var.gcp_region

  rate_limits {
    max_concurrent_dispatches = 10
    max_dispatches_per_second = 5
  }

  retry_config {
    max_attempts       = 5
    max_backoff        = "3600s"
    min_backoff        = "1s"
    max_doublings      = 5
  }

  depends_on = [google_project_service.apis]
}

# ============================================
# SHARED HTTPS LOAD BALANCER
# One LB for all apps, each app adds a backend
# ============================================

# URL map - default backend (placeholder, apps add path rules)
# Initially points to a default backend, apps add path-based routing
resource "google_compute_url_map" "shared" {
  name            = "factory-floor-urlmap"
  description     = "Shared URL map for all Factory Floor apps"
  default_service = google_compute_backend_service.default.id
}

# Default backend (returns 404 for unmatched routes)
resource "google_compute_backend_service" "default" {
  name        = "factory-floor-default-backend"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10

  # Attach Cloud Armor to the shared LB
  security_policy = google_compute_security_policy.factory_floor.id

  # No backends - returns error for unmatched paths
  # Each app adds its own backend via path rules
}

# HTTPS proxy
resource "google_compute_target_https_proxy" "shared" {
  name             = "factory-floor-https-proxy"
  url_map          = google_compute_url_map.shared.id
  ssl_certificates = [] # Uses default Google-managed cert
}

# Global forwarding rule (the actual load balancer)
resource "google_compute_global_forwarding_rule" "shared" {
  name                  = "factory-floor-lb"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.shared.id
}

# HTTP to HTTPS redirect
resource "google_compute_url_map" "http_redirect" {
  name = "factory-floor-http-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "http_redirect" {
  name    = "factory-floor-http-proxy"
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http_redirect" {
  name                  = "factory-floor-http-lb"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_redirect.id
}
