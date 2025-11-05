# AWS KMS Key Management

This directory contains KMS key configurations that mirror the Azure Key Vault setup.

## Modules

### key-management/
Creates and manages KMS keys for:
- Service-level encryption (S3, RDS, EBS, etc.)
- Application-level encryption
- Key rotation policies
- Cross-account key sharing

## AWS KMS vs Azure Key Vault

| Feature | Azure Key Vault | AWS KMS + Secrets Manager |
|---------|----------------|---------------------------|
| Encryption Keys | ✓ Keys | ✓ KMS |
| Secrets | ✓ Secrets | ✓ Secrets Manager |
| Certificates | ✓ Certificates | AWS ACM (separate) |
| Hardware HSM | ✓ Premium tier | ✓ CloudHSM (separate) |
| Key Rotation | Manual/Auto | Automatic (yearly) |
| Access Control | RBAC + Access Policies | IAM Policies + Key Policies |

## Key Differences

**Azure Key Vault**: All-in-one service for keys, secrets, and certificates

**AWS Approach**: Separate services
- KMS for encryption keys
- Secrets Manager for secrets
- ACM for certificates
- Parameter Store for configuration

## When to Use What

- **KMS**: Encrypt data at rest (S3, EBS, RDS)
- **Secrets Manager**: Database credentials, API keys
- **Parameter Store**: Application configuration, non-secret data
- **ACM**: SSL/TLS certificates for load balancers
