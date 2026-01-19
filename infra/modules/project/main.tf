# Factory Floor - Per-Project Module
# Creates Cloud Run service with Load Balancer + Cloud Armor
#
# Usage:
#   module "my_app" {
#     source                          = "../modules/project"
#     app_name                        = "my-app"
#     gcp_project_id                  = var.gcp_project_id
#     cloud_armor_policy_name         = data.terraform_remote_state.global.outputs.cloud_armor_policy_name
#     cloud_run_service_account_email = data.terraform_remote_state.global.outputs.cloud_run_service_account_email
#     vpc_connector_id                = data.terraform_remote_state.global.outputs.vpc_connector_id
#   }

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

locals {
  service_name = "ff-${var.app_name}"
}

# ============================================
# CLOUD RUN SERVICE
# ============================================

resource "google_cloud_run_v2_service" "app" {
  name     = local.service_name
  location = var.gcp_region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" # Only via LB

  template {
    service_account = var.cloud_run_service_account_email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    vpc_access {
      connector = var.vpc_connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = var.container_image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      # Environment variables
      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secrets from Secret Manager
      dynamic "env" {
        for_each = var.secrets
        content {
          name = env.value.name
          value_source {
            secret_key_ref {
              secret  = env.value.secret_id
              version = env.value.version
            }
          }
        }
      }

      # Health check
      startup_probe {
        http_get {
          path = "/health"
        }
        initial_delay_seconds = 5
        period_seconds        = 10
        failure_threshold     = 3
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# ============================================
# SERVERLESS NEG (Network Endpoint Group)
# ============================================

resource "google_compute_region_network_endpoint_group" "app" {
  name                  = "${local.service_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.gcp_region

  cloud_run {
    service = google_cloud_run_v2_service.app.name
  }
}

# ============================================
# HTTPS LOAD BALANCER
# ============================================

# Backend service
resource "google_compute_backend_service" "app" {
  name        = "${local.service_name}-backend"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.app.id
  }

  # Attach Cloud Armor
  security_policy = "projects/${var.gcp_project_id}/global/securityPolicies/${var.cloud_armor_policy_name}"

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# URL map
resource "google_compute_url_map" "app" {
  name            = "${local.service_name}-urlmap"
  default_service = google_compute_backend_service.app.id
}

# Managed SSL certificate (uses *.run.app domain)
# For custom domains, add google_compute_managed_ssl_certificate

# HTTPS proxy
resource "google_compute_target_https_proxy" "app" {
  name             = "${local.service_name}-https-proxy"
  url_map          = google_compute_url_map.app.id
  ssl_certificates = [] # Uses default Google-managed cert for run.app
}

# Global forwarding rule (the actual load balancer)
resource "google_compute_global_forwarding_rule" "app" {
  name                  = "${local.service_name}-lb"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.app.id
}

# HTTP to HTTPS redirect
resource "google_compute_url_map" "http_redirect" {
  name = "${local.service_name}-http-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "http_redirect" {
  name    = "${local.service_name}-http-proxy"
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http_redirect" {
  name                  = "${local.service_name}-http-lb"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_redirect.id
}

# ============================================
# PROJECT-SPECIFIC SECRETS
# ============================================

resource "google_secret_manager_secret" "supabase_url" {
  secret_id = "${var.app_name}-supabase-url"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "supabase_anon_key" {
  secret_id = "${var.app_name}-supabase-anon-key"

  replication {
    auto {}
  }
}
