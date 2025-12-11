# GCP Compute Engine Baseline

> *"Your virtual machines, but in the cloud and cooler"* 💻☁️

This module creates baseline Google Compute Engine (GCE) instances with security best practices and free tier optimization.

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

- **Free Tier Optimized**: Uses `e2-micro` instances (744 hours/month free)
- **Security Hardening**: OS Login, secure boot, shielded VMs
- **Auto-Updates**: Automatic OS patching and security updates
- **Monitoring**: Cloud Monitoring agent pre-installed
- **SSH Access**: Secure SSH via IAP (Identity-Aware Proxy)

## Free Tier Benefits

✅ **1 f1-micro instance**: 744 hours/month (always-free)  
✅ **30 GB standard disk**: Persistent storage included  
✅ **1 GB outbound traffic**: Per month to most regions  
✅ **Cloud Monitoring**: Basic metrics and alerting  

## Instance Types

| Type | vCPU | Memory | Use Case | Free Tier |
|------|------|--------|----------|----------|
| `e2-micro` | 0.25-2 | 1 GB | Dev/test | ✅ Yes |
| `e2-small` | 0.5-2 | 2 GB | Light workloads | ❌ No |
| `e2-medium` | 1-2 | 4 GB | Standard apps | ❌ No |

---

🚧 **Under Construction**: This module is a template. Add your compute resources to `main.tf`.

See [Compute Engine documentation](https://cloud.google.com/compute/docs) for examples.