resource "google_project_iam_member" "project" {
  for_each = { for p in local.project_permissions : "${p.role}_${p.member}" => p }

  project = var.project
  role    = "roles/${each.value.role}"
  member  = each.value.member

  depends_on = [
    local.validate_environment,
  ]
}

resource "google_bigquery_dataset_iam_member" "dataset" {
  for_each = { for p in local.dataset_permissions : "${p.dataset_name}_${p.role}_${p.member}" => p }

  project    = var.project
  dataset_id = google_bigquery_dataset.managed_datasets[each.value.dataset_name].dataset_id
  role       = "roles/${each.value.role}"
  member     = each.value.member

  lifecycle {
    replace_triggered_by = [
      google_bigquery_dataset.managed_datasets[each.value.dataset_name]
    ]
  }
}

resource "google_storage_bucket_iam_member" "bucket" {
  for_each = { for p in local.bucket_permissions : "${p.bucket_name}_${p.role}_${p.member}" => p }

  bucket = google_storage_bucket.buckets[each.value.bucket_name].name
  role   = "roles/${each.value.role}"
  member = each.value.member

  lifecycle {
    replace_triggered_by = [
      google_storage_bucket.buckets[each.value.bucket_name]
    ]
  }
}