# gcp-foundation-module

Reusable Terraform modules for the [`infrastructure-terraform-gcp`](https://github.com/sinex-cloud/infrastructure-terraform-gcp)
platform. Two independent modules, consumed by tag from that repo — nothing
here is applied directly.

## Modules

### Root — data platform

BigQuery datasets, Cloud Storage buckets, and project/dataset/bucket-level
IAM, entirely driven by a `foundation.yaml` file (see the consuming repo's
`foundation-config/foundation.yaml` for the schema in practice — datasets
under `managed_datasets`, buckets under `buckets`, project-level grants
under `additional_project_permissions`).

| Variable | Description |
|---|---|
| `path_to_yaml_resources_file` | Path to the environment's `foundation.yaml` |
| `env` | `dev` or `int` |
| `project` | GCP project ID |

Outputs: `dataset_ids`, `bucket_names` (both keyed by name).

### `agent-hosting/` — review-agent platform

Cloud Run service, its service accounts and IAM bindings, Secret Manager
containers, Artifact Registry repo, the review-artifacts GCS bucket, and the
Cloud Build Developer Connect connection — the infrastructure the
review/apply agent runs on. Gated to `env == "dev"` by a
`lifecycle.precondition`; intentionally not deployable to `int`.

| Variable | Description |
|---|---|
| `env` | `dev` or `int` (only `dev` currently allowed) |
| `project` | GCP project ID |
| `region` | Region for Cloud Run, Artifact Registry, review-artifacts bucket |

## Usage

Consumed by tag, not by branch, from the other repo's root `main.tf`:

```hcl
module "data_platform" {
  source                      = "git::https://github.com/sinex-cloud/gcp-foundation-module.git?ref=vX.Y.Z"
  path_to_yaml_resources_file = "${path.module}/foundation-config/foundation.yaml"
  env                         = var.env
  project                     = var.project
}

module "agent_hosting" {
  source  = "git::https://github.com/sinex-cloud/gcp-foundation-module.git//agent-hosting?ref=vX.Y.Z"
  env     = var.env
  project = var.project
  region  = "europe-west1"
}
```

Each path (root, `agent-hosting/`) is versioned and pinned independently —
they can sit on different tags in the consuming repo at the same time.

## Releasing

Tag `main` after a change lands (`vMAJOR.MINOR.PATCH`); the consuming repo
bumps its `?ref=` once the tag exists. No CI publishes these — tagging is
manual.
