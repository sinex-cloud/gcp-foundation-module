variable "path_to_yaml_resources_file" {
  type        = string
  description = "Path to the foundation.yaml file describing this environment's project permissions, datasets, and buckets"
}

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
