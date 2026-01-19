# Project Module Variables
# Per-app configuration

variable "app_name" {
  description = "Application name (used for resource naming)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.app_name))
    error_message = "App name must be lowercase, start with letter, 3-21 chars, alphanumeric and hyphens only."
  }
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "url_map_name" {
  description = "Shared URL map name (from global module)"
  type        = string
}

variable "cloud_run_service_account_email" {
  description = "Cloud Run service account email (from global module)"
  type        = string
}

variable "vpc_connector_id" {
  description = "VPC connector ID (from global module)"
  type        = string
}

variable "container_image" {
  description = "Container image for Cloud Run"
  type        = string
  default     = "gcr.io/cloudrun/hello" # Placeholder, replaced on deploy
}

variable "min_instances" {
  description = "Minimum Cloud Run instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum Cloud Run instances"
  type        = number
  default     = 10
}

variable "cpu" {
  description = "CPU allocation"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory allocation"
  type        = string
  default     = "512Mi"
}

variable "environment_variables" {
  description = "Environment variables for Cloud Run"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secret Manager secrets to mount"
  type = list(object({
    name       = string
    secret_id  = string
    version    = string
  }))
  default = []
}
