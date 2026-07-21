resource "google_storage_bucket" "buckets" {
  for_each = local.buckets

  project       = var.project
  name = "${var.project}-${each.key}"
  location      = each.value.location
  force_destroy = true

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  labels = {
    environment = var.env
    managed_by  = "terraform"
  }

  depends_on = [
    local.validate_environment,
  ]
}