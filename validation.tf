locals {
  valid_environments = ["dev", "int"]

  validate_environment = (
    contains(local.valid_environments, var.env)
    ? null
    : file("ERROR: environment '${var.env}' must be one of: ${join(", ", local.valid_environments)}")
  )
}