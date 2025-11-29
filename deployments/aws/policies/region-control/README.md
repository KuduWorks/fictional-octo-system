# AWS Region Control Policies

This module restricts AWS resource creation to approved regions using Service Control Policies (SCPs). It mirrors the Azure region control policy functionality.

## What This Creates

### Service Control Policy (SCP)
**RegionRestriction** - Multi-layered approach to region enforcement:

1. **General Region Restriction** - Denies all AWS operations outside approved regions
   - Uses `NotAction` to exclude global services
   - Applies to regional services (EC2, RDS, Lambda, etc.)

2. **S3-Specific Region Restriction** - Special handling for S3's global namespace
   - Denies `s3:CreateBucket` outside allowed regions using `s3:LocationConstraint`
   - Blocks default us-east-1 bucket creation

3. **Global Services Exemption** - Allows services without regional endpoints:
   - IAM, Organizations, Route53, CloudFront
   - Billing, Support, Cost Explorer
   - S3 global operations (list buckets, account settings)

### Enforcement
- Attached at **organization root** level for maximum coverage
- Immediate blocking of non-compliant operations
- No drift - policies cannot be disabled at account level

## Region Restriction Behavior

### Blocked Operations
Any AWS API call attempting to create, modify, or access resources in non-approved regions will be **denied immediately**.

Example blocked actions:
- `aws ec2 run-instances --region us-east-1` ❌
- `aws s3api create-bucket --bucket test --region us-west-2` ❌
- `aws rds create-db-instance --region eu-west-1` ❌
- `aws lambda create-function --region ap-southeast-1` ❌

### Allowed Operations
- ✅ All operations in `eu-north-1` (Stockholm)
- ✅ Global services (IAM, Organizations, Route53, CloudFront, WAF, Shield)
- ✅ Billing and support operations
- ✅ S3 global operations (ListAllMyBuckets, GetAccountPublicAccessBlock)

## Azure Equivalent

This mirrors Azure's region control policy:

| Azure | AWS |
|-------|-----|
| Policy: Allowed locations | SCP: RegionRestriction |
| Effect: Deny | Effect: Deny |
| Scope: Subscription | Scope: Organization Root |
| Enforcement: Immediate | Enforcement: Immediate |

## Prerequisites

1. **AWS Organizations** - Your account must be part of an AWS Organization
2. **Management Account Access** - SCPs must be deployed from the management account
3. **Appropriate Permissions** - `organizations:CreatePolicy` and `organizations:AttachPolicy`

## Verification

Check if you're in an organization:

```bash
aws organizations describe-organization
```

If you see organization details, you're good to go. If you get an error, you'll need to:
1. Create an AWS Organization, or
2. Deploy from the management account

## Usage

### Initial Deployment

```bash
cd deployments/aws/policies/region-control/

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### Testing Region Restrictions

After deployment, test that the SCP is working:

```bash
# This should SUCCEED (Stockholm region)
aws s3 mb s3://test-bucket-$(date +%s) --region eu-north-1

# This should FAIL (Ohio region)
aws s3api create-bucket --bucket test-bucket-$(date +%s) --region us-east-2 \
  --create-bucket-configuration LocationConstraint=us-east-2

# Expected error: AccessDenied or similar
```

### Cleanup Non-Compliant Resources

Use the cleanup script to find and delete buckets in non-approved regions:

```bash
./cleanup-test-buckets.sh
```

This script:
- Scans all AWS regions for buckets
- Identifies buckets outside Stockholm
- Identifies buckets with public access
- Prompts for confirmation before deletion

## Important Notes

### SCP Propagation Time
⏳ **Allow 5-15 minutes** after deployment for SCPs to propagate to all AWS regions and endpoints. During propagation, some blocked operations may temporarily succeed.

### Global Services Exception
The SCP explicitly allows global services (IAM, Organizations, Route53, CloudFront, billing, support) to function properly since they don't have regional endpoints.

### Existing Resources
The SCP **does not** remove existing resources in non-approved regions. It only prevents **new** operations. Use the cleanup script to remove non-compliant resources.

### S3 Special Handling
S3 requires special treatment because:
- Bucket namespace is global across all regions
- `CreateBucket` API uses `LocationConstraint` parameter instead of `RequestedRegion`
- Default bucket creation targets us-east-1 (empty LocationConstraint)

## Compliance Mapping

- **ISO 27001 A.11.2.1** - Equipment siting and protection (geographic control)
- **GDPR Article 44** - Transfer of data to third countries (regional data residency)
- **Swedish Data Protection** - Data sovereignty requirements
- **NIST 800-53 SA-9** - External information system services location

## Troubleshooting

### Error: "AWSOrganizationsNotInUseException"
You're not in an AWS Organization. Either create one or use an alternative approach (IAM policies, CloudFormation StackSets).

### Error: "PolicyTypeNotEnabledException"
Service Control Policies are not enabled. Enable them:
```bash
aws organizations enable-policy-type --root-id <ROOT_ID> --policy-type SERVICE_CONTROL_POLICY
```

### Error: "AccessDeniedException"
You don't have permissions to create SCPs. Ensure you're deploying from the management account with appropriate IAM permissions.

### Tests Failing After Deployment
SCPs can take 5-15 minutes to propagate globally. Wait and re-run tests.

### Global Services Not Working
Check that the exempted services list in the SCP includes the service you're trying to use. Common global services are already excluded.

## Outputs

- `organization_id` - Your AWS Organization ID
- `organization_root_id` - Root organizational unit ID
- `region_restriction_policy_id` - The SCP policy ID
- `region_restriction_policy_arn` - The SCP policy ARN
- `allowed_regions` - List of approved regions

## Variables

- `allowed_regions` - List of permitted AWS regions (default: `["eu-north-1"]`)
- `aws_region` - Region for deploying resources (default: `eu-north-1`)
- `environment` - Environment name (default: `prod`)

## Testing Region Restrictions

### Automated Test Script

Use the included test script to verify SCP enforcement:

```bash
./test-scps.sh
```

This tests:
1. ❌ Creating bucket in blocked region (Ohio) - Should FAIL
2. ✅ Creating bucket in approved region (Stockholm) - Should SUCCEED
3. ❌ Making bucket public with ACL - Should FAIL
4. ❌ Removing public access block - Should FAIL
5. ✅ Creating private bucket in Stockholm - Should SUCCEED

### Manual Testing

After deployment, test region restrictions manually:
