# AWS Cross-Account Role for SCP Testing

This Terraform configuration creates an IAM role in the member account that can be assumed from the management account for testing Service Control Policies (SCPs).

## What This Creates

- **IAM Role**: `CrossAccountTestRole` in member account (`<YOUR-MEMBER-ACCOUNT-ID>`)
- **Trust Policy**: Allows management account (`<YOUR-MANAGEMENT-ACCOUNT-ID>`) to assume the role
- **Permissions**: AdministratorAccess for full testing capabilities
- **Security**: Requires ExternalId for additional protection

## Prerequisites

⚠️ **IMPORTANT**: AWS automatically creates `OrganizationAccountAccessRole` in new member accounts. This Terraform configuration will **use** that existing role to deploy the `CrossAccountTestRole`.

Before deploying:
1. Member account must exist
2. SCPs must be attached to member account
3. Wait 5-15 minutes for SCP propagation

## Deployment

```bash
cd deployments/aws/iam/cross-account-role

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply
```

## Testing SCPs

After deployment, use the outputted commands to assume the role and test:

```bash
# 1. Get credentials by assuming the role
aws sts assume-role \
  --role-arn arn:aws:iam::<YOUR-MEMBER-ACCOUNT-ID>:role/CrossAccountTestRole \
  --role-session-name test-session \
  --external-id <YOUR-SECURE-EXTERNAL-ID> \
  > /tmp/assume-role-output.json

# 2. Extract and export credentials
export AWS_ACCESS_KEY_ID=$(cat /tmp/assume-role-output.json | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/assume-role-output.json | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(cat /tmp/assume-role-output.json | jq -r .Credentials.SessionToken)

# 3. Verify you're in the member account
aws sts get-caller-identity
# Should show: "Account": "<YOUR-MEMBER-ACCOUNT-ID>"

# 4. Test region restriction (should FAIL with AccessDenied)
aws s3api create-bucket \
  --bucket test-ohio-$(date +%s) \
  --region us-east-2 \
  --create-bucket-configuration LocationConstraint=us-east-2

# Expected: AccessDenied - SCPs block non-Stockholm regions

# 5. Test Stockholm region (should SUCCEED)
aws s3api create-bucket \
  --bucket test-stockholm-$(date +%s) \
  --region eu-north-1 \
  --create-bucket-configuration LocationConstraint=eu-north-1

# Expected: Success - Stockholm is allowed

# 6. Test public ACL on Stockholm bucket (should FAIL)
BUCKET_NAME=test-stockholm-$(date +%s)
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region eu-north-1 \
  --create-bucket-configuration LocationConstraint=eu-north-1

aws s3api put-bucket-acl \
  --bucket $BUCKET_NAME \
  --acl public-read \
  --region eu-north-1

# Expected: AccessDenied - SCPs block public access

# 7. Clean up test buckets
aws s3 rb s3://$BUCKET_NAME --region eu-north-1

# 8. Unset credentials when done
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

## How It Works

1. **OrganizationAccountAccessRole** (auto-created by AWS):
   - Exists in member account by default
   - Allows management account root to assume it
   - Used by Terraform to deploy resources

2. **CrossAccountTestRole** (created by this module):
   - More secure with ExternalId requirement
   - Can be used for testing without root access
   - Has full AdministratorAccess for comprehensive testing

3. **SCPs Apply**:
   - When you assume role in member account
   - SCPs enforce at the API level
   - Blocks non-compliant operations immediately

## Security Notes

- **ExternalId**: Adds protection against confused deputy problem. **You must generate your own unique, secret external ID value.** Never use publicly documented examples or shared values. Generate one using:
  ```bash
  # Using uuidgen
  uuidgen
  
  # Or using OpenSSL
  openssl rand -hex 16
  ```
- **Management Account Bypass**: Remember the management account (`<YOUR-MANAGEMENT-ACCOUNT-ID>`) bypasses SCPs
- **Member Account Enforcement**: SCPs only apply to member accounts
- **Session Duration**: Assumed role credentials expire after 1 hour by default

## Troubleshooting

### "AccessDenied" when running terraform apply
- Ensure you're running from management account
- Verify OrganizationAccountAccessRole exists in member account
- Check your IAM permissions in management account

### "AccessDenied" when assuming CrossAccountTestRole
- Verify ExternalId matches your configured value
- Check trust policy allows management account
- Ensure role exists in member account

### SCPs not blocking operations
- Wait 5-15 minutes for SCP propagation
- Verify SCPs are attached: `aws organizations list-policies-for-target --target-id <YOUR-MEMBER-ACCOUNT-ID> --filter SERVICE_CONTROL_POLICY`
- Confirm you're testing from member account (not management account)

## Cleanup

To remove the cross-account role:

```bash
terraform destroy
```

Note: This only removes CrossAccountTestRole. The member account and SCPs remain.
