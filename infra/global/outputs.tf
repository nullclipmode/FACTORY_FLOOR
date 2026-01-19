# Outputs - Used by project module

output "cloud_armor_policy_id" {
  description = "Cloud Armor security policy ID"
  value       = google_compute_security_policy.factory_floor.id
}

output "cloud_armor_policy_name" {
  description = "Cloud Armor security policy name"
  value       = google_compute_security_policy.factory_floor.name
}

output "cloud_run_service_account_email" {
  description = "Cloud Run service account email"
  value       = google_service_account.cloud_run.email
}

output "vpc_connector_id" {
  description = "VPC connector ID for Cloud Run"
  value       = google_vpc_access_connector.factory_floor.id
}

output "cloud_tasks_queue_name" {
  description = "Cloud Tasks queue name"
  value       = google_cloud_tasks_queue.default.name
}

output "vpc_network_name" {
  description = "VPC network name"
  value       = google_compute_network.factory_floor.name
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.factory_floor.name
}

# Shared Load Balancer outputs
output "load_balancer_ip" {
  description = "Shared Load Balancer IP address"
  value       = google_compute_global_forwarding_rule.shared.ip_address
}

output "url_map_id" {
  description = "Shared URL map ID (apps add backends here)"
  value       = google_compute_url_map.shared.id
}

output "url_map_name" {
  description = "Shared URL map name"
  value       = google_compute_url_map.shared.name
}

output "default_backend_service_id" {
  description = "Default backend service ID"
  value       = google_compute_backend_service.default.id
}
