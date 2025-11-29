# AWS Policy Configurations

This directory contains AWS compliance and governance policies that mirror the Azure Policy setup with **preventive enforcement** using Service Control Policies.

## Modules

### encryption-baseline/
**Status**: ✅ Fully Implemented with SCPs

Mirrors `azure/policies/iso27001-crypto/` and `security-baseline/`

AWS Config rules and SCPs for:
- ✅ S3 bucket encryption enforcement
- ✅ S3 public access blocking (prevention + detection)
- ✅ Account-level S3 public access blocks
- ✅ EBS volume encryption
- ✅ RDS encryption requirements
- ✅ DynamoDB KMS encryption
- ✅ CloudTrail encryption
- ✅ TLS/SSL enforcement

**Key Features**:
- Service Control Policies prevent public S3 buckets
- Account-level public access block enforced
- Config rules provide continuous monitoring
- Defense in depth approach

### region-control/
**Status**: ✅ Fully Implemented with SCPs

Mirrors `azure/policies/region-control/`

Service Control Policies (SCPs) for:
- ✅ Restricting resource creation to Stockholm (eu-north-1)
- ✅ S3-specific region controls using LocationConstraint
- ✅ Global service exemptions (IAM, Route53, CloudFront, billing)
- ✅ Immediate enforcement at API level

**Key Features**:
- Denies ALL operations outside approved regions
- Special handling for S3's global namespace
- Exempts truly global services
- Organization-level enforcement

### resource-tagging/
**Status**: 📋 Planned

AWS tagging policies for:
- Required tag enforcement
- Tag-based access control
- Cost allocation tags

## Enforcement Model: AWS vs Azure

### Azure Policy Approach
```terraform
enforcement_mode = "Default"  # Blocks at ARM API
effect = "Deny"               # Prevents deployment
```

### AWS Approach (This Implementation)
```terraform
enable_scps = true                    # Blocks at AWS API
type = "SERVICE_CONTROL_POLICY"      # Prevents execution
effect = "Deny"                       # Hard enforcement
```

## AWS Config vs Azure Policy

| Capability | AWS Implementation | Azure Equivalent |
|-----------|-------------------|------------------|
| **Prevention** | Service Control Policies (SCPs) | Policy with Deny effect |
| **Detection** | AWS Config Rules | Policy with Audit effect |
| **Remediation** | Config + Lambda (planned) | deployIfNotExists/modify |
| **Scope** | Organization Root | Subscription/Management Group |
| **Propagation** | 5-15 minutes | Immediate |

### Key Differences

**Azure**: Policies evaluate at deployment time (Azure Resource Manager)
**AWS**: SCPs evaluate at API call time (every AWS service)

**Azure**: Single policy can do prevention + detection
**AWS**: Separate mechanisms (SCPs for prevention, Config for detection)

**Azure**: Built-in remediation effects
**AWS**: Requires Lambda functions for remediation

## Deployment Order

1. **First**: Deploy `region-control/` to establish geographic boundaries
2. **Second**: Deploy `encryption-baseline/` to enforce security controls
3. **Verify**: Wait 5-15 minutes for SCP propagation
4. **Test**: Run included test scripts to verify enforcement

## Getting Started

Each subdirectory is a standalone Terraform module. Navigate to the specific module and initialize:

```bash
cd encryption-baseline/
terraform init
terraform plan
```
