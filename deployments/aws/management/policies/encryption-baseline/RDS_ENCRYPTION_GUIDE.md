# RDS Encryption Quick Reference

## ✅ What's Configured

Your AWS environment now enforces RDS encryption for both data at rest and data in transit:

### 1. Data at Rest (Storage Encryption)
- **AWS Config Rule**: `rds-storage-encrypted`
- **Monitors**: All RDS instances for storage encryption
- **Alerts**: Non-compliant instances via SNS

### 2. Data in Transit (SSL/TLS Encryption)
- **4 Parameter Groups Created**:
  - `postgresql-ssl-required` - Forces SSL for PostgreSQL
  - `mysql-ssl-required` - Forces SSL for MySQL
  - `aurora-postgresql-ssl-required` - Forces SSL for Aurora PostgreSQL
  - `aurora-mysql-ssl-required` - Forces SSL for Aurora MySQL

## 📋 How to Use

When creating RDS instances, reference these parameter groups:

### PostgreSQL Example
```hcl
resource "aws_db_instance" "example" {
  identifier           = "my-db"
  engine              = "postgres"
  engine_version      = "16.1"
  
  storage_encrypted   = true                      # ✅ Encryption at rest
  parameter_group_name = "postgresql-ssl-required" # ✅ Encryption in transit
}
```

### MySQL Example
```hcl
resource "aws_db_instance" "example" {
  identifier           = "my-db"
  engine              = "mysql"
  engine_version      = "8.0.35"
  
  storage_encrypted   = true                   # ✅ Encryption at rest
  parameter_group_name = "mysql-ssl-required"  # ✅ Encryption in transit
}
```

### Aurora PostgreSQL Example
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier   = "my-cluster"
  engine              = "aurora-postgresql"
  engine_version      = "16.1"
  
  storage_encrypted   = true                                        # ✅ Encryption at rest
  db_cluster_parameter_group_name = "aurora-postgresql-ssl-required" # ✅ Encryption in transit
}
```

### Aurora MySQL Example
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier   = "my-cluster"
  engine              = "aurora-mysql"
  engine_version      = "8.0.mysql_aurora.3.05.2"
  
  storage_encrypted   = true                                   # ✅ Encryption at rest
  db_cluster_parameter_group_name = "aurora-mysql-ssl-required" # ✅ Encryption in transit
}
```

## ✔️ Verification

### Check Parameter Value (PostgreSQL)
```bash
psql -h your-endpoint.rds.amazonaws.com -U username -d database \
  -c "SHOW rds.force_ssl;"
```
Expected output: `rds.force_ssl = on`

### Check Parameter Value (MySQL)
```bash
mysql -h your-endpoint.rds.amazonaws.com -u username -p \
  -e "SHOW VARIABLES LIKE 'require_secure_transport';"
```
Expected output: `require_secure_transport = ON`

### Check Encryption at Rest
```bash
aws rds describe-db-instances \
  --db-instance-identifier my-db \
  --query 'DBInstances[0].StorageEncrypted'
```
Expected output: `true`

## 📊 Monitoring

View compliance in AWS Config:
```bash
aws configservice describe-compliance-by-config-rule \
  --config-rule-names rds-storage-encrypted
```

Or visit: https://console.aws.amazon.com/config/home?region=eu-north-1#/dashboard

## 🔐 Security Checklist

- [x] RDS storage encryption enabled via Config rule
- [x] SSL/TLS parameter groups created for all RDS engine types
- [x] Compliance monitoring active
- [x] SNS alerts configured for violations
- [ ] Apply parameter groups to existing RDS instances
- [ ] Verify SSL enforcement on all databases
- [ ] Document database connection strings require SSL

## 📝 Next Steps

1. **Update existing RDS instances** to use the SSL-enforcing parameter groups
2. **Verify SSL is active** using the verification commands above
3. **Update application connection strings** to use SSL (if not already)
4. **Check AWS Config dashboard** for any non-compliant resources

## ⚠️ Important Notes

- **Parameter group changes** require instance reboot
- **Aurora changes** typically don't require reboot but may take a few minutes
- **Version compatibility**: Update the `family` in main.tf if using different engine versions
- **Existing instances**: Apply parameter groups manually or via Terraform

## 🛠️ Troubleshooting

### Issue: "Cannot use parameter group family X with engine version Y"
**Solution**: Update the `family` parameter in [main.tf](main.tf) lines 412, 425, 438, 451 to match your engine version.

### Issue: SSL still not enforced after applying parameter group
**Solution**: 
1. Verify parameter group is attached: `aws rds describe-db-instances --db-instance-identifier my-db`
2. Reboot the instance: `aws rds reboot-db-instance --db-instance-identifier my-db`
3. Check parameter value using verification commands above
