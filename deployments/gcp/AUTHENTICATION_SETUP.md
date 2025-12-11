# 🚨 GCP Authentication Setup Guide

## Issue: Google Cloud Credentials Not Found

The error `google: could not find default credentials` means you need to authenticate with Google Cloud first.

## 🛠️ Quick Fix (Choose One Method)

### Method 1: Install Google Cloud CLI (Recommended)

1. **Install Google Cloud CLI**:
   ```bash
   # Download and install from: https://cloud.google.com/sdk/docs/install
   # Or use winget on Windows:
   winget install Google.CloudSDK
   ```

2. **Authenticate**:
   ```bash
   # Login to your Google account
   gcloud auth login
   
   # Set up Application Default Credentials
   gcloud auth application-default login
   
   # Set your default project
   gcloud config set project <YOUR-PROJECT-ID>
   ```

3. **Verify Setup**:
   ```bash
   gcloud auth list
   gcloud config list
   ```

### Method 2: Use Service Account Key (Temporary)

If you can't install gcloud CLI right now:

1. **Create a service account** in the Google Cloud Console
2. **Download the JSON key** file  
3. **Set environment variable**:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="path/to/your/service-account-key.json"
   ```

## 🎯 After Authentication

Once authenticated, retry the bootstrap:

```bash
cd deployments/gcp/bootstrap/state-storage/
terraform init
terraform plan
terraform apply
```

## ✅ Success Checklist

- [ ] Google Cloud CLI installed
- [ ] Authenticated with `gcloud auth login`
- [ ] Application Default Credentials set
- [ ] Default project configured
- [ ] `terraform init` works without errors

## 🔗 Helpful Links

- [Install Google Cloud CLI](https://cloud.google.com/sdk/docs/install)
- [Application Default Credentials](https://cloud.google.com/docs/authentication/external/set-up-adc)
- [GCP Authentication Guide](https://cloud.google.com/docs/authentication/getting-started)

---

**Next Steps**: After authentication is working, the bootstrap module will create your GCS state bucket and Workload Identity Federation setup automatically! 🚀