# AWS VPC Networking Module

This module creates a foundational VPC infrastructure optimized for serverless workloads with cost-efficient connectivity.

## Architecture

- **VPC**: 10.0.0.0/23 (512 IPs)
- **Public Subnets**: 2 subnets across 2 AZs (10.0.0.0/25, 10.0.0.128/25)
- **Private Subnets**: 2 subnets across 2 AZs (10.0.1.0/25, 10.0.1.128/25)
- **Gateway Endpoints**: S3 and DynamoDB (free)
- **No NAT Gateways**: Cost optimization for serverless architecture
- **Availability Zones**: eu-north-1a, eu-north-1b

## Resources Created

1. **VPC** with DNS enabled
2. **Internet Gateway** for public subnet connectivity
3. **4 Subnets**: 2 public (auto-assign public IPs), 2 private
4. **Route Tables**: Public (routes to IGW), Private (local only)
5. **Gateway Endpoints**: S3 and DynamoDB (no data transfer costs)
6. **Default Security Group**: Restrictive (egress only)

## Cost Estimate

- **VPC, Subnets, IGW, Route Tables**: $0.00
- **Gateway Endpoints (S3, DynamoDB)**: $0.00
- **Total**: ~$0.00/month

**Note**: This network design has zero standing costs. NAT Gateways are intentionally omitted ($32/month each). For Lambda functions requiring internet access from private subnets, consider:
- Using VPC endpoints for AWS services (free gateway endpoints)
- Deploying in public subnets with public IPs
- Adding NAT Gateway only when absolutely necessary

## Prerequisites

- AWS account with VPC creation permissions
- Terraform state backend configured (see terraform-state-bootstrap module)
- Region control SCP allows eu-north-1

## Deployment Steps

### 1. Local State Deployment

```bash
cd deployments/aws/networking

# Copy example files
cp terraform.tfvars.example terraform.tfvars
cp backend.tf.example backend.tf

# Edit terraform.tfvars with your values
# Keep backend.tf commented out for local state

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

### 2. Capture Outputs

```bash
terraform output -json > outputs.json
cat outputs.json  # Save VPC ID and subnet IDs
```

### 3. Backend Migration

```bash
# Uncomment backend.tf configuration
# Update bucket name to match your state bucket
# Example: fictional-octo-system-tfstate-123456789012

# Migrate state
terraform init -migrate-state

# Confirm migration
terraform plan  # Should show no changes
```

## Outputs

| Output | Description | Example |
|--------|-------------|---------|
| `vpc_id` | VPC identifier | vpc-0abc123def456 |
| `vpc_cidr` | VPC CIDR block | 10.0.0.0/23 |
| `public_subnet_a_id` | Public subnet AZ-a | subnet-0abc123 |
| `public_subnet_b_id` | Public subnet AZ-b | subnet-0def456 |
| `private_subnet_a_id` | Private subnet AZ-a | subnet-0ghi789 |
| `private_subnet_b_id` | Private subnet AZ-b | subnet-0jkl012 |
| `s3_endpoint_id` | S3 gateway endpoint | vpce-0abc123 |
| `dynamodb_endpoint_id` | DynamoDB gateway endpoint | vpce-0def456 |

## Usage Examples

### Lambda Function in Private Subnet

```hcl
resource "aws_lambda_function" "example" {
  function_name = "example-function"
  
  vpc_config {
    subnet_ids         = [data.terraform_remote_state.networking.outputs.private_subnet_a_id]
    security_group_ids = [aws_security_group.lambda.id]
  }
}
```

### Application Load Balancer

```hcl
resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [
    data.terraform_remote_state.networking.outputs.public_subnet_a_id,
    data.terraform_remote_state.networking.outputs.public_subnet_b_id
  ]
}
```

## Troubleshooting

### Issue: Lambda can't access internet from private subnet

**Cause**: Private subnets have no NAT Gateway (cost optimization).

**Solutions**:
1. Use VPC endpoints for AWS services (S3, DynamoDB already configured)
2. Deploy Lambda in public subnet with auto-assign public IP
3. Add NAT Gateway if internet access required (adds $32/month cost)

### Issue: VPC endpoint not working

**Verification**:
```bash
aws ec2 describe-vpc-endpoints --vpc-id <VPC-ID> --region eu-north-1
```

**Check**:
- Endpoint associated with correct route tables
- Security groups allow traffic
- DNS resolution enabled in VPC

### Issue: Subnet IP exhaustion

**Current Capacity**: Each subnet has 128 IPs (123 usable after AWS reserves 5).

**Solution**: If more IPs needed, expand VPC CIDR with secondary CIDR block:
```bash
aws ec2 associate-vpc-cidr-block --vpc-id <VPC-ID> --cidr-block 10.0.2.0/23 --region eu-north-1
```

## Security Considerations

1. **Default Security Group**: Restrictive by default (egress only)
2. **Public Subnets**: Auto-assign public IPs enabled for resources that need internet access
3. **Private Subnets**: No direct internet access (use endpoints for AWS services)
4. **Gateway Endpoints**: Free data transfer for S3/DynamoDB traffic within VPC
5. **No Flow Logs**: Cost optimization (add if traffic analysis needed ~$0.50/GB)

## Module Dependencies

- **None** - This is a foundational module
- Can be deployed immediately after terraform-state-bootstrap

## Related Modules

- `terraform-state-bootstrap`: Creates S3 backend for Terraform state
- `policies/region-control`: Enforces eu-north-1 region (allows this VPC deployment)

## References

- [AWS VPC Pricing](https://aws.amazon.com/vpc/pricing/)
- [VPC Gateway Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html)
- [NAT Gateway Alternatives](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
