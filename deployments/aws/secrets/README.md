# AWS Secrets Management

This directory contains AWS Secrets Manager configurations for secure credential storage and rotation.

## What This Includes

- Secret creation and management
- Automatic secret rotation
- Cross-account secret sharing
- Integration with RDS for database credentials

## AWS Secrets Manager vs Parameter Store

| Feature | Secrets Manager | Parameter Store |
|---------|----------------|-----------------|
| Encryption | Always encrypted | Optional |
| Rotation | Built-in | Manual |
| Cost | ~$0.40/secret/month | Free (Standard) / $0.05 (Advanced) |
| Use Case | Secrets, credentials | Configuration, parameters |
| Versioning | Automatic | Automatic |
| Cross-region | Replication | Manual |

## When to Use Secrets Manager

- Database credentials (with auto-rotation)
- API keys requiring rotation
- OAuth tokens
- License keys
- Any secret requiring compliance audit

## When to Use Parameter Store

- Application configuration
- Non-sensitive settings
- Feature flags
- Environment variables
- Simple secrets without rotation needs
