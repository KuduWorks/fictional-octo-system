# AWS Networking

This directory contains VPC and networking configurations that mirror the Azure vnet setup.

## Modules

### vpc-baseline/
Creates foundational networking infrastructure:
- VPC with public and private subnets
- NAT gateways for outbound internet access
- VPC endpoints for AWS services
- Network ACLs and security groups
- Flow logs for network monitoring

## Azure VNet vs AWS VPC

| Azure | AWS |
|-------|-----|
| Virtual Network (VNet) | Virtual Private Cloud (VPC) |
| Subnet | Subnet |
| Network Security Group (NSG) | Security Group + Network ACL |
| Route Table | Route Table |
| NAT Gateway | NAT Gateway |
| Private Link | VPC Endpoint (PrivateLink) |
| VNet Peering | VPC Peering |
| Virtual Network Gateway | Virtual Private Gateway |

## Key Differences

**Subnets**:
- Azure: Regional resource (spans AZs)
- AWS: AZ-specific (must create per AZ)

**Security**:
- Azure: NSGs at subnet or NIC level
- AWS: Security Groups (stateful) + NACLs (stateless)

**DNS**:
- Azure: Built-in or Azure DNS
- AWS: Route 53 + VPC DNS resolver

## Common Patterns

- Multi-tier architecture (public/private/database subnets)
- HA across multiple availability zones
- VPC endpoints for S3, DynamoDB, etc. (reduce NAT costs)
- Transit Gateway for multi-VPC connectivity
