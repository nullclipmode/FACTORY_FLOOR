# Project Module Outputs

output "cloud_run_service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.app.name
}

output "cloud_run_uri" {
  description = "Cloud Run service URI (internal)"
  value       = google_cloud_run_v2_service.app.uri
}

output "backend_service_name" {
  description = "Backend service name (for URL map path rules)"
  value       = google_compute_backend_service.app.name
}

output "backend_service_id" {
  description = "Backend service ID (for URL map path rules)"
  value       = google_compute_backend_service.app.id
}

output "neg_id" {
  description = "Serverless NEG ID"
  value       = google_compute_region_network_endpoint_group.app.id
}

output "supabase_url_secret_id" {
  description = "Supabase URL secret ID"
  value       = google_secret_manager_secret.supabase_url.secret_id
}

output "supabase_anon_key_secret_id" {
  description = "Supabase anon key secret ID"
  value       = google_secret_manager_secret.supabase_anon_key.secret_id
}
