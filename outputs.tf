output "dataset_ids" {
  description = "BigQuery dataset IDs managed in this environment, keyed by dataset name"
  value       = { for name, dataset in google_bigquery_dataset.managed_datasets : name => dataset.dataset_id }
}

output "bucket_names" {
  description = "Cloud Storage bucket names managed in this environment, keyed by bucket key"
  value       = { for name, bucket in google_storage_bucket.buckets : name => bucket.name }
}
