# AWS Compute Automation

This directory contains Systems Manager automation that mirrors the Azure vm-automation setup.

## Modules

### ssm-automation/
Systems Manager automation documents for:
- EC2 instance patching
- Automated backup and snapshot management
- Configuration drift detection
- Run command automation
- State Manager configurations

## AWS Systems Manager vs Azure VM Automation

| Azure | AWS |
|-------|-----|
| Automation Runbooks | SSM Automation Documents |
| Update Management | Patch Manager |
| Run Command | Run Command |
| State Configuration (DSC) | State Manager |
| Change Tracking | AWS Config |

## Key Features

- **Patch Manager**: Automated OS and application patching
- **Run Command**: Execute scripts on EC2 instances remotely
- **State Manager**: Enforce desired state configurations
- **Automation Documents**: Multi-step workflows for common tasks
- **Session Manager**: Secure shell access without SSH keys

## Prerequisites

- EC2 instances with SSM agent installed
- IAM instance profile with SSM permissions
- VPC endpoints for private subnet instances (optional)

## Common Use Cases

1. Automated patching schedules
2. Disaster recovery automation
3. Configuration enforcement
4. Compliance scanning
5. Software installation
