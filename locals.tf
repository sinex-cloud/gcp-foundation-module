locals {
  # -----------------------------
  # Load + parse config
  # -----------------------------
  content_yaml_resources_file = file(var.path_to_yaml_resources_file)
  yaml                        = yamldecode(local.content_yaml_resources_file)

  member_type_prefixes = {
    users            = "user"
    groups           = "group"
    service_accounts = "serviceAccount"
  }

  # -----------------------------
  # Labels applied to every labellable resource.
  # Static metadata comes from the config; environment and managed_by are
  # derived here so they can never drift from the deployment they describe.
  # -----------------------------
  common_labels = merge(
    try(local.yaml.labels, {}),
    {
      environment = var.env
      managed_by  = "terraform"
    }
  )

  # -----------------------------
  # Project-level IAM
  # -----------------------------
  project_permissions = flatten([
    for permission in try(local.yaml.additional_project_permissions, []) : [
      for member_type, members in permission.members : [
        for member in members : {
          role   = permission.role
          member = "${local.member_type_prefixes[member_type]}:${member}"
        }
      ]
    ] if contains(permission.environments, var.env)
  ])

  # -----------------------------
  # Datasets + dataset-level IAM
  # Only datasets that declare this environment are managed here.
  # -----------------------------
  datasets = {
    for dataset_name, dataset in local.yaml.managed_datasets : dataset_name => dataset
    if contains(dataset.environments, var.env)
  }

  dataset_permissions = flatten([
    for dataset_name, dataset in local.datasets : [
      for permission in try(dataset.permissions, []) : [
        for member_type, members in permission.members : [
          for member in members : {
            dataset_name = dataset_name
            role         = permission.role
            member       = "${local.member_type_prefixes[member_type]}:${member}"
          }
        ]
      ]
    ]
  ])

  # -----------------------------
  # Buckets + bucket-level IAM
  # Only buckets that declare this environment are managed here.
  # -----------------------------
  buckets = {
    for bucket_name, bucket in local.yaml.buckets : bucket_name => bucket
    if contains(bucket.environments, var.env)
  }

  bucket_permissions = flatten([
    for bucket_name, bucket in local.buckets : [
      for permission in try(bucket.permissions, []) : [
        for member_type, members in permission.members : [
          for member in members : {
            bucket_name = bucket_name
            role        = permission.role
            member      = "${local.member_type_prefixes[member_type]}:${member}"
          }
        ]
      ]
    ]
  ])
}
