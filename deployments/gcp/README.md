## GCP Deployments 🔴

Short and friendly GCP Terraform recipes — bootstrap state, configure workload identity, then deploy the modules you need.  Finland (`europe-north1`) is our primary playground.

Table of contents
- [Quick Start](#quick-start)
- [Auth (local & CI)](#auth-local--ci)
- [State backend](#state-backend)
- [Compute & Networking](#compute--networking)
- [Monitoring & Cost](#monitoring--cost)
- [Help & Troubleshooting](#help--troubleshooting)

Quick notes
- Region: `europe-north1` (primary) — fallback `europe-west1` for DR.
- Workload Identity is preferred for GitHub Actions — avoid service account keys.

## Quick Start

1. Authenticate locally:
```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <your-project-id>
```
2. Bootstrap state (run first):
```bash
cd bootstrap/state-storage/
terraform init && terraform apply
```
3. Deploy a module (example):
```bash
cd ../iam/workload-identity/
terraform init && terraform apply
```

## Auth (local & CI)

- Local: use Application Default Credentials (`gcloud auth application-default login`). No key files, fewer tears.
- CI: use [Workload Identity Federation](iam/workload-identity/). See `deployments/gcp/iam/workload-identity/README.md`.

## State backend

Use GCS for Terraform state. Example backend:
```hcl
terraform {
  backend "gcs" {
    bucket = "fictional-octo-system-tfstate-<project-id>"
    prefix = "gcp/service/module/terraform.tfstate"
  }
}
```

## Compute & Networking

- Compute: `deployments/gcp/compute/gce-baseline/` (GCE). Kubernetes/GKE is planned (coming soon).
- Networking: `deployments/gcp/networking/` for VPC and firewall modules.

## Monitoring & Cost

- Monitoring: Cloud Monitoring / Logging; see `deployments/gcp/monitoring/`.
- Cost: budgets live under `deployments/gcp/cost-management/`.

## Help & Troubleshooting

- Quickstart: [QUICKSTART.md](QUICKSTART.md)
- Bootstrap guide: [bootstrap/state-storage/README.md](bootstrap/state-storage/README.md)
- Common commands:
```bash
gcloud auth list
gcloud config list
gsutil ls gs://fictional-octo-system-tfstate-<project-id>
```

---

Want more detail? Dive into the folder for the module you care about — this file is just the elevator pitch (with a joke or two). 🚀