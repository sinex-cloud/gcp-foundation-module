variable "env" {
  type        = string
  description = "Environment name (dev, int)"

  validation {
    condition     = contains(["dev", "int"], var.env)
    error_message = "env must be one of: dev, int."
  }
}

variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "Region for the Cloud Run service, Artifact Registry, and review-artifacts bucket"
}
