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

## ⚠️ Critical: Management Account Does NOT Enforce SCPs

**AWS Design Limitation**: SCPs never apply to the management account (master account). This is by design to prevent accidental lockout.

### Impact
- Management account (<YOUR-MGMT-ACCOUNT-ID>): **Bypasses all SCPs** ❌
- Member accounts (e.g., <YOUR-MEMBER-ACCOUNT-ID>): **SCPs enforced** ✅

### Testing Strategy

**Wrong Way** ❌:
```bash
# Testing from management account - SCPs won't work!
aws s3api create-bucket --bucket test --region us-east-2
# SUCCESS (false negative - policy not enforced)
```

**Right Way** ✅:
```bash
# 1. Assume role in member account
aws sts assume-role --role-arn arn:aws:iam::<YOUR-MEMBER-ACCOUNT-ID>:role/CrossAccountTestRole \
  --role-session-name test --external-id <YOUR-SECURE-EXTERNAL-ID>

# 2. Export credentials (see cross-account-role README)

# 3. Test - SCPs now enforced!
aws s3api create-bucket --bucket test --region us-east-2
# AccessDenied (correct - policy working!)
```

See: [cross-account-role setup](../iam/cross-account-role/README.md)

## Deployment Order

1. **First**: Deploy `region-control/` to establish geographic boundaries
2. **Second**: Deploy `encryption-baseline/` to enforce security controls
3. **Third**: Set up [cross-account-role](../iam/cross-account-role/) for proper testing
4. **Verify**: Wait 5-15 minutes for SCP propagation
5. **Test**: Assume role in member account and run test scripts

## Getting Started

Each subdirectory is a standalone Terraform module. Navigate to the specific module and initialize:

```bash
cd encryption-baseline/
terraform init
terraform plan
```
