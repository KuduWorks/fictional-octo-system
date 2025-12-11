# GCP VPC Baseline

> *"Building the digital highways for your cloud traffic"* 🛛️☁️

This module creates a baseline Virtual Private Cloud (VPC) network configuration for secure, isolated cloud networking in GCP.

## Quick Start

```bash
# Copy backend configuration
cp backend.tf.example backend.tf
sed -i 's/<YOUR-PROJECT-ID>/your-project-id/g' backend.tf

# Deploy
terraform init
terraform apply
```

## Features

- **Custom VPC**: Non-default VPC for better security
- **Regional Subnets**: Subnets in Europe North (Finland) region
- **Firewall Rules**: Secure-by-default network rules
- **Private Google Access**: Access Google services without public IPs
- **Flow Logs**: Network traffic logging for security and debugging

## Network Design

```
┌─────────────────────────────┐
│        VPC Network          │
│    (europe-north1)          │
│                             │
│  ┌─────────────────────┐  │
│  │   Public Subnet     │  │
│  │   10.0.1.0/24       │  │
│  └─────────────────────┘  │
│                             │
│  ┌─────────────────────┐  │
│  │   Private Subnet    │  │
│  │   10.0.2.0/24       │  │
│  └─────────────────────┘  │
└─────────────────────────────┘
```

## Multi-Cloud Integration

Integrates with your existing multi-cloud networking:

- **AWS**: VPC in `eu-north-1` (Stockholm)
- **Azure**: VNet in `swedencentral` (Sweden)
- **GCP**: VPC in `europe-north1` (Finland)

---

🚧 **Under Construction**: This module is a template. Add your VPC resources to `main.tf`.

See [VPC documentation](https://cloud.google.com/vpc/docs) for examples.