resource "google_bigquery_dataset" "managed_datasets" {
  for_each = local.datasets

  dataset_id = each.key
  project    = var.project
  location   = each.value.location

  labels = {
    environment = var.env
    managed_by  = "terraform"
  }

  depends_on = [
    local.validate_environment,
  ]
}