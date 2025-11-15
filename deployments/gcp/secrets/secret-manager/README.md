# GCP Secret Manager

> *"Where secrets go to live their best encrypted life"* 🤐🔐

This module manages Google Cloud Secret Manager for secure storage of application secrets, API keys, and sensitive configuration.

## Quick Start

```bash
# Copy backend configuration
cp backend.tf.example backend.tf
sed -i 's/PROJECT-ID/your-project-id/g' backend.tf

# Deploy
terraform init
terraform apply
```

## Features

- **Automatic Replication**: Secrets replicated across regions
- **IAM Integration**: Fine-grained access control
- **Versioning**: Automatic secret version management
- **Audit Logging**: Full access audit trail
- **Free Tier**: 6 secret versions per month included

## Common Use Cases

- Database connection strings
- API keys and tokens
- SSL certificates
- Application configuration secrets
- CI/CD secrets and credentials

---

🚧 **Under Construction**: This module is a template. Add your secret resources to `main.tf`.

See [Google Secret Manager documentation](https://cloud.google.com/secret-manager/docs) for examples.