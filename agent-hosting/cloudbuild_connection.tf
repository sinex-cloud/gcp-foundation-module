# Cloud Build's own GitHub connection (Developer Connect), source of truth
# for review.cloudbuild.yaml's PR-branch source -- separate from the custom
# GitHub App used for webhook delivery and PR comments (github_app_design.md).
#
# The connection itself was created manually (`gcloud builds connections
# create github infra-review-dev`), same manual-install pattern as the
# custom GitHub App -- it needs a one-time browser OAuth consent Terraform
# can't drive. These resources exist so state tracks them; `terraform import`
# both rather than letting `apply` try to recreate.

resource "google_cloudbuildv2_connection" "github" {
  project  = var.project
  location = var.region
  name     = "infra-review-${var.env}"

  github_config {
    app_installation_id = null # set by the manual GitHub App install, not Terraform-managed
    authorizer_credential {
      oauth_token_secret_version = "" # managed by Cloud Build's own P4SA, not this module
    }
  }

  lifecycle {
    ignore_changes = [github_config]
  }
}

resource "google_cloudbuildv2_repository" "infrastructure_terraform_gcp" {
  project           = var.project
  location          = var.region
  name              = "infrastructure-terraform-gcp"
  parent_connection = google_cloudbuildv2_connection.github.name
  remote_uri        = "https://github.com/sinex-cloud/infrastructure-terraform-gcp.git"
}
