locals {
  valid_environments = local.yaml.project.environments

  validate_environment = (
    contains(local.valid_environments, var.env)
    ? null
    : file("ERROR: environment '${var.env}' must be one of: ${join(", ", local.valid_environments)}")
  )
}