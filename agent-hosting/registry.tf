resource "google_artifact_registry_repository" "agent_images" {
  location      = var.region
  repository_id = "infra-agent-images-${var.env}"
  format        = "DOCKER"
  description   = "Container images for the infra-review agent Cloud Run service (${var.env})"

  labels = {
    platform    = "data-platform" # matches foundation.yaml's static labels, so scope-reporting stays consistent
    owner       = "data-engineering"
    application = "infra-review"
    environment = var.env
    managed_by  = "terraform"
    component   = "agent-registry"
  }
}
