# Global Infrastructure Variables
# These are set once and rarely change

variable "gcp_project_id" {
  description = "GCP Project ID (shared across all apps)"
  type        = string
}

variable "gcp_region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "Default GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
