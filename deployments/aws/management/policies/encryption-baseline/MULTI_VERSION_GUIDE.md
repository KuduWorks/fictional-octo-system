# Multi-Version RDS SSL/TLS Parameter Groups

## ✅ Complete Solution

Your encryption baseline now supports **ALL major RDS database versions** - no more version compatibility issues!

## 📋 Available Parameter Groups

### PostgreSQL (5 versions)
| Version | Parameter Group Name | Family |
|---------|---------------------|---------|
| PostgreSQL 12 | `postgresql-postgres12-ssl-required` | postgres12 |
| PostgreSQL 13 | `postgresql-postgres13-ssl-required` | postgres13 |
| PostgreSQL 14 | `postgresql-postgres14-ssl-required` | postgres14 |
| PostgreSQL 15 | `postgresql-postgres15-ssl-required` | postgres15 |
| PostgreSQL 16 | `postgresql-postgres16-ssl-required` | postgres16 |

**SSL Parameter**: `rds.force_ssl = 1`

---

### MySQL (2 versions)
| Version | Parameter Group Name | Family |
|---------|---------------------|---------|
| MySQL 5.7 | `mysql-mysql57-ssl-required` | mysql5.7 |
| MySQL 8.0 | `mysql-mysql80-ssl-required` | mysql8.0 |

**SSL Parameter**: `require_secure_transport = ON`

---

### Aurora PostgreSQL (4 versions)
| Version | Parameter Group Name | Family |
|---------|---------------------|---------|
| Aurora PostgreSQL 13 | `aurora-postgresql13-ssl-required` | aurora-postgresql13 |
| Aurora PostgreSQL 14 | `aurora-postgresql14-ssl-required` | aurora-postgresql14 |
| Aurora PostgreSQL 15 | `aurora-postgresql15-ssl-required` | aurora-postgresql15 |
| Aurora PostgreSQL 16 | `aurora-postgresql16-ssl-required` | aurora-postgresql16 |

**SSL Parameter**: `rds.force_ssl = 1`

---

### Aurora MySQL (2 versions)
| Version | Parameter Group Name | Family |
|---------|---------------------|---------|
| Aurora MySQL 5.7 | `aurora-mysql5-7-ssl-required` | aurora-mysql5.7 |
| Aurora MySQL 8.0 | `aurora-mysql8-0-ssl-required` | aurora-mysql8.0 |

**SSL Parameter**: `require_secure_transport = ON`

**Note**: Dots in version numbers are replaced with hyphens in parameter group names due to AWS naming restrictions.

---

## 🎯 How It Works

### Using `for_each` for Multi-Version Support

The Terraform configuration uses `for_each` loops to create parameter groups for all supported versions:

```hcl
locals {
  postgresql_families = ["postgres12", "postgres13", "postgres14", "postgres15", "postgres16"]
  mysql_families      = ["mysql5.7", "mysql8.0"]
  aurora_pg_families  = ["aurora-postgresql13", "aurora-postgresql14", "aurora-postgresql15", "aurora-postgresql16"]
  aurora_my_families  = ["aurora-mysql5.7", "aurora-mysql8.0"]
}

resource "aws_db_parameter_group" "postgresql_ssl_required" {
  for_each = toset(local.postgresql_families)
  
  name   = "postgresql-${each.value}-ssl-required"
  family = each.value
  # ... SSL configuration
}
```

This approach:
- ✅ Creates parameter groups for all versions automatically
- ✅ Makes it easy to add/remove versions by updating the locals
- ✅ Ensures consistent SSL configuration across all versions
- ✅ No need to manually manage each version

---

## 💡 Usage Examples

### Match Your Database Version

```hcl
# PostgreSQL 15 instance
resource "aws_db_instance" "app_db" {
  engine              = "postgres"
  engine_version      = "15.4"
  parameter_group_name = "postgresql-postgres15-ssl-required"  # ✅ Version 15
  storage_encrypted   = true
}

# MySQL 5.7 instance
resource "aws_db_instance" "legacy_db" {
  engine              = "mysql"
  engine_version      = "5.7.44"
  parameter_group_name = "mysql-mysql57-ssl-required"  # ✅ Version 5.7
  storage_encrypted   = true
}

# Aurora PostgreSQL 16 cluster
resource "aws_rds_cluster" "main_cluster" {
  engine              = "aurora-postgresql"
  engine_version      = "16.1"
  db_cluster_parameter_group_name = "aurora-postgresql16-ssl-required"  # ✅ Version 16
  storage_encrypted   = true
}

# Aurora MySQL 8.0 cluster
resource "aws_rds_cluster" "analytics_cluster" {
  engine              = "aurora-mysql"
  engine_version      = "8.0.mysql_aurora.3.05.2"
  db_cluster_parameter_group_name = "aurora-mysql8-0-ssl-required"  # ✅ Version 8.0
  storage_encrypted   = true
}
```

---

## 🔍 Version Compatibility Checking

The parameter group `family` must match your database engine version:

| Engine Version | Compatible Family |
|---------------|-------------------|
| postgres 12.x | postgres12 |
| postgres 13.x | postgres13 |
| postgres 14.x | postgres14 |
| postgres 15.x | postgres15 |
| postgres 16.x | postgres16 |
| mysql 5.7.x | mysql5.7 |
| mysql 8.0.x | mysql8.0 |
| aurora-postgresql 13.x | aurora-postgresql13 |
| aurora-postgresql 14.x | aurora-postgresql14 |
| aurora-postgresql 15.x | aurora-postgresql15 |
| aurora-postgresql 16.x | aurora-postgresql16 |
| aurora-mysql 5.7.x | aurora-mysql5.7 |
| aurora-mysql 8.0.x | aurora-mysql8.0 |

---

## 🚀 Benefits of Multi-Version Support

### Before (Single Version)
```hcl
# Only worked with Postgres 16
resource "aws_db_parameter_group" "postgresql_ssl_required" {
  name   = "postgresql-ssl-required"
  family = "postgres16"  # ❌ Fixed to version 16
}
```

**Problem**: If you had Postgres 15, 14, or 13 instances, you couldn't use this parameter group!

### After (All Versions)
```hcl
# Works with ALL PostgreSQL versions
resource "aws_db_parameter_group" "postgresql_ssl_required" {
  for_each = toset(["postgres12", "postgres13", "postgres14", "postgres15", "postgres16"])
  
  name   = "postgresql-${each.value}-ssl-required"
  family = each.value  # ✅ Creates one for each version
}
```

**Solution**: Now you have a parameter group for every supported version!

---

## 📝 Adding New Versions

When AWS releases new versions, simply update the locals:

```hcl
locals {
  # Add postgres17 when available
  postgresql_families = ["postgres12", "postgres13", "postgres14", "postgres15", "postgres16", "postgres17"]
}
```

Then run `terraform apply` to create the new parameter groups.

---

## ✅ Verification

List all parameter groups:

```bash
# PostgreSQL
aws rds describe-db-parameter-groups \
  --query "DBParameterGroups[?contains(DBParameterGroupName, 'postgresql')].DBParameterGroupName"

# MySQL
aws rds describe-db-parameter-groups \
  --query "DBParameterGroups[?contains(DBParameterGroupName, 'mysql')].DBParameterGroupName"

# Aurora PostgreSQL
aws rds describe-db-cluster-parameter-groups \
  --query "DBClusterParameterGroups[?contains(DBClusterParameterGroupName, 'aurora-postgresql')].DBClusterParameterGroupName"

# Aurora MySQL
aws rds describe-db-cluster-parameter-groups \
  --query "DBClusterParameterGroups[?contains(DBClusterParameterGroupName, 'aurora-mysql')].DBClusterParameterGroupName"
```

---

## 🎉 Summary

You now have:
- ✅ 13 total parameter groups covering all major RDS versions
- ✅ Automatic SSL/TLS enforcement for any RDS database version
- ✅ No more "family mismatch" errors
- ✅ Easy to maintain and extend
- ✅ Complete encryption at rest (AWS Config) + in transit (parameter groups)

Your RDS encryption policy is now **future-proof** and works with any database version! 🔒
