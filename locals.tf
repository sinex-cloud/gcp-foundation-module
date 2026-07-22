locals {
  # -----------------------------
  # Load + parse config
  # -----------------------------
  content_yaml_resources_file = file(var.path_to_yaml_resources_file)
  yaml                        = yamldecode(local.content_yaml_resources_file)

  project_short_name = local.yaml.project.project_short_name
  member_type_prefixes = {
    users             = "user"
    groups            = "group"
    service_accounts  = "serviceAccount"
  }

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
  # -----------------------------
  datasets = local.yaml.managed_datasets

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
  # -----------------------------
  buckets = local.yaml.buckets

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