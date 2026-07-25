resource "google_bigquery_dataset" "managed_datasets" {
  for_each = local.datasets

  dataset_id = each.key
  project    = var.project
  location   = each.value.location

  labels = merge(
    local.common_labels,
    { component = "bigquery" },
    try(each.value.labels, {})
  )
}
