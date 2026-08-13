# --- Service accounts -------------------------------------------------

resource "google_service_account" "agent_review" {
  account_id   = "sa-agent-review-${var.env}"
  display_name = "Infra review agent (Cloud Run) - ${var.env}"
}

resource "google_service_account" "cb_plan" {
  account_id   = "sa-cb-plan-${var.env}"
  display_name = "Cloud Build PR review/plan pipeline - ${var.env}"
}

resource "google_service_account" "cb_apply" {
  account_id   = "sa-cb-apply-${var.env}"
  display_name = "Cloud Build apply pipeline - ${var.env}"
}

# Existing deployment SA, created manually during bootstrap -----------------
# Referenced by constructed resource path, not a data source: reading the SA
# via the API would run as the impersonated deployer SA itself, which is
# never granted iam.serviceAccounts.get during bootstrap.

locals {
  tf_deployer_id = "projects/${var.project}/serviceAccounts/sa-tf-deployer-${var.env}@${var.project}.iam.gserviceaccount.com"
}

# --- Logging: custom SAs need this explicitly (no default compute SA here) ---

resource "google_project_iam_member" "agent_review_log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.agent_review.email}"
}

# --- Agent triggers Cloud Build (cloudbuild_client.py) for each reviewed PR ---

resource "google_project_iam_member" "agent_review_triggers_builds" {
  project = var.project
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.agent_review.email}"
}

# builds.editor alone can't read the Developer Connect repository referenced
# by source.connectedRepository -- that needs cloudbuild.repositories.get,
# only granted by connectionViewer (or a higher connection role).
resource "google_project_iam_member" "agent_review_reads_connection" {
  project = var.project
  role    = "roles/cloudbuild.connectionViewer"
  member  = "serviceAccount:${google_service_account.agent_review.email}"
}

# The build review.cloudbuild.yaml creates runs as cb_plan (serviceAccount
# field in the YAML) -- agent_review, as the caller creating that build,
# needs actAs on cb_plan specifically, same as any resource launched to run
# as another SA.
resource "google_service_account_iam_member" "agent_review_acts_as_cb_plan" {
  service_account_id = google_service_account.cb_plan.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.agent_review.email}"
}

# Same reasoning as above, for apply.cloudbuild.yaml running as cb_apply.
resource "google_service_account_iam_member" "agent_review_acts_as_cb_apply" {
  service_account_id = google_service_account.cb_apply.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.agent_review.email}"
}

resource "google_project_iam_member" "cb_plan_log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cb_plan.email}"
}

resource "google_project_iam_member" "cb_apply_log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cb_apply.email}"
}

# --- Plan pipeline needs to write review artifacts (bucket-scoped, not project-wide) ---

resource "google_storage_bucket_iam_member" "cb_plan_writes_artifacts" {
  bucket = google_storage_bucket.review_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cb_plan.email}"
}

# --- cb_plan runs as a custom SA, so it needs explicit read access to the
# auto-created Cloud Build staging bucket (gcloud builds submit uploads
# source there before the build starts) ---

resource "google_storage_bucket_iam_member" "cb_plan_reads_source_staging" {
  bucket = "${var.project}_cloudbuild"
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cb_plan.email}"
}

# --- Agent needs to read its two secrets (secret-scoped, not project-wide) ---

resource "google_secret_manager_secret_iam_member" "agent_reads_github_app_key" {
  secret_id = google_secret_manager_secret.platform["github-app-key"].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.agent_review.email}"
}

resource "google_secret_manager_secret_iam_member" "agent_reads_webhook_secret" {
  secret_id = google_secret_manager_secret.platform["github-webhook-secret"].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.agent_review.email}"
}

# --- cb_plan mints a GitHub App JWT to post the review as a PR comment
# (final step of review.cloudbuild.yaml) ---

resource "google_secret_manager_secret_iam_member" "cb_plan_reads_github_app_key" {
  secret_id = google_secret_manager_secret.platform["github-app-key"].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cb_plan.email}"
}

# --- cb_apply posts the apply result as a PR comment
# (post-apply-comment step of apply.cloudbuild.yaml) ---

resource "google_secret_manager_secret_iam_member" "cb_apply_reads_github_app_key" {
  secret_id = google_secret_manager_secret.platform["github-app-key"].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cb_apply.email}"
}

# --- cb_plan calls the LLM provider to generate the AI review
# (review-generation step of review.cloudbuild.yaml) ---

resource "google_secret_manager_secret_iam_member" "cb_plan_reads_model_api_key" {
  secret_id = google_secret_manager_secret.platform["model-api-key"].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cb_plan.email}"
}

# --- cb_plan / cb_apply impersonate sa-tf-deployer to run Terraform ---

resource "google_service_account_iam_member" "cb_plan_impersonates_deployer" {
  service_account_id = local.tf_deployer_id
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.cb_plan.email}"
}

resource "google_service_account_iam_member" "cb_apply_impersonates_deployer" {
  service_account_id = local.tf_deployer_id
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.cb_apply.email}"
}
