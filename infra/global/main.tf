# Factory Floor - Global Infrastructure

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

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
    "vpcaccess.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_security_policy" "factory_floor" {
  name        = "factory-floor-armor"
  description = "Global Cloud Armor policy for all Factory Floor apps"

  rule {
    priority = 1000
    action   = "deny(403)"
    match {
      expr {
        expression = "request.headers['user-agent'].contains('GPTBot')"
      }
    }
    description = "Block GPTBot"
  }

  rule {
    priority = 1001
    action   = "deny(403)"
    match {
      expr {
        expression = "request.headers['user-agent'].contains('ClaudeBot')"
      }
    }
    description = "Block ClaudeBot"
  }

  rule {
    priority = 1002
    action   = "deny(403)"
    match {
      expr {
        expression = "request.headers['user-agent'].contains('CCBot')"
      }
    }
    description = "Block CCBot"
  }

  rule {
    priority = 1003
    action   = "deny(403)"
    match {
      expr {
        expression = "request.headers['user-agent'].contains('Bytespider')"
      }
    }
    description = "Block Bytespider"
  }

  rule {
    priority = 2000
    action   = "deny(403)"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
    description = "SQL injection protection"
  }

  rule {
    priority = 2001
    action   = "deny(403)"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
    description = "XSS protection"
  }

  rule {
    priority = 2147483647
    action   = "allow"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow rule"
  }

  depends_on = [google_project_service.apis]
}

resource "google_service_account" "cloud_run" {
  account_id   = "factory-floor-run"
  display_name = "Factory Floor Cloud Run"
  description  = "Service account for Cloud Run services"
}

resource "google_project_iam_member" "cloud_run_secrets" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_project_iam_member" "cloud_run_tasks" {
  project = var.gcp_project_id
  role    = "roles/cloudtasks.enqueuer"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_project_iam_member" "cloud_run_logging" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_project_iam_member" "cloud_run_vertex" {
  project = var.gcp_project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_secret_manager_secret" "supabase_service_key" {
  secret_id = "supabase-service-key"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "sentry_dsn" {
  secret_id = "sentry-dsn"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret" "mixpanel_token" {
  secret_id = "mixpanel-token"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

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
  private_ip_google_access = true
}

resource "google_vpc_access_connector" "factory_floor" {
  name          = "factory-floor-connector"
  region        = var.gcp_region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.factory_floor.name
  depends_on = [google_project_service.apis]
}

resource "google_cloud_tasks_queue" "default" {
  name     = "factory-floor-tasks"
  location = var.gcp_region

  rate_limits {
    max_concurrent_dispatches = 10
    max_dispatches_per_second = 5
  }

  retry_config {
    max_attempts  = 5
    max_backoff   = "3600s"
    min_backoff   = "1s"
    max_doublings = 5
  }

  depends_on = [google_project_service.apis]
}

resource "google_compute_backend_service" "default" {
  name        = "factory-floor-default-backend"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10
  security_policy = google_compute_security_policy.factory_floor.id
}

resource "google_compute_url_map" "shared" {
  name            = "factory-floor-urlmap"
  description     = "Shared URL map for all Factory Floor apps"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_https_proxy" "shared" {
  name    = "factory-floor-https-proxy"
  url_map          = google_compute_url_map.shared.id
  ssl_certificates = ["projects/core-infra-484804/global/sslCertificates/factory-floor-cert"]
}

resource "google_compute_global_forwarding_rule" "shared" {
  name                  = "factory-floor-lb"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.shared.id
}

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
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_redirect.id
}
