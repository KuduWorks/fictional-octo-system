# ⚠️ WARNINGS AND IMPORTANT NOTICES

> *"Read this before you deploy anything, or prepare to learn some expensive lessons"* 💸🔥

This document contains critical warnings and important notices for deploying and managing infrastructure with this repository. **Please read carefully before proceeding.**

## 🚨 Critical Warnings

### Cost-Related Warnings

#### Azure Costs
- **⚠️ Azure Bastion**: Costs approximately $140-180/month per deployment when running 24/7. Use VM automation schedules to reduce costs.
- **⚠️ NAT Gateway**: Data processing charges apply per GB. Monitor your outbound traffic.
- **⚠️ Log Analytics**: Ingestion costs can escalate quickly. Review retention policies (default: 30 days).
- **⚠️ Storage Accounts**: Even "idle" storage accounts incur monthly charges. Monitor storage metrics.
- **⚠️ Azure Monitor**: Alert rule costs are per-rule per-month. Don't create hundreds of alert rules.

#### AWS Costs
- **⚠️ Data Transfer**: Cross-region and internet egress charges can be substantial. Keep resources in the same region (eu-north-1).
- **⚠️ KMS Keys**: $1/month per key. Plan your key strategy to avoid unnecessary keys.
- **⚠️ AWS Config**: Charges per configuration item recorded and per rule evaluation.
- **⚠️ Secrets Manager**: $0.40/month per secret plus API call charges. Consider consolidation.
- **⚠️ EC2 Instances**: Don't forget to stop development instances when not in use.

**💡 RECOMMENDATION**: Always set up budget alerts before deploying production workloads!

### Security Warnings

#### State File Security
- **⚠️ NEVER commit `terraform.tfstate` files**: They contain sensitive data including secrets, keys, and connection strings.
- **⚠️ Remote state access**: Ensure IP whitelisting is properly configured before accessing state files.
- **⚠️ State locking**: Always use locking (DynamoDB for AWS, Storage Account for Azure) to prevent concurrent modifications.

#### Secrets Management
- **⚠️ Azure Key Vault Purge Protection**: When enabled (recommended), deleted secrets are retained for 90 days and cannot be permanently purged. Plan accordingly.
- **⚠️ Never hardcode secrets**: Use Key Vault or Secrets Manager, and reference them via data sources.
- **⚠️ Service Principal secrets**: Rotate regularly (90-180 days). Expired secrets will break automation.
- **⚠️ terraform.tfvars**: This file often contains sensitive data. Ensure it's in `.gitignore`.

#### Network Security
- **⚠️ Public IP exposure**: VMs should NOT have public IPs. Use Azure Bastion or AWS Systems Manager Session Manager.
- **⚠️ Firewall rules**: Review all NSG/Security Group rules. Default deny should be the baseline.
- **⚠️ Storage account access**: IP restrictions are critical. Don't open storage to `0.0.0.0/0`.

### Operational Warnings

#### Dynamic IP Management
- **⚠️ Automated IP updates**: The wrapper scripts (`tf.sh`, `tf.ps1`) automatically update your IP. Manual Terraform commands will fail if your IP changes.
- **⚠️ IP accumulation**: Old IPs accumulate in storage firewall rules. Run `cleanup-old-ips.sh` periodically.
- **⚠️ VPN/Proxy users**: Your detected IP may not match your actual source IP. Verify with `curl ifconfig.me`.

#### Terraform State
- **⚠️ State file corruption**: Never manually edit state files. Use `terraform state` commands.
- **⚠️ Backend migration**: Migrating state backends requires careful planning. Always backup before migration.
- **⚠️ State file size**: Large state files (>10MB) slow down operations. Consider using separate state files per component.

#### Resource Deletion
- **⚠️ Destructive operations**: `terraform destroy` is irreversible. Always backup data before destroying resources.
- **⚠️ Soft delete**: Azure Key Vault and other services have soft-delete periods (7-90 days). Recreating with the same name requires purging first.
- **⚠️ Dependency order**: Terraform may not always calculate dependency order correctly. Review the destroy plan carefully.

### Compliance and Policy Warnings

#### Azure Policies
- **⚠️ Assignment scope**: Policy assignments at subscription level affect all resources. Test at resource group level first.
- **⚠️ Deny policies**: Can prevent legitimate deployments. Use audit mode first, then switch to deny.
- **⚠️ Policy effects**: Understand the difference between Deny, Audit, Append, Modify, and DeployIfNotExists.

#### AWS Config Rules
- **⚠️ Compliance evaluation**: Rules evaluate resources retroactively. Existing non-compliant resources will trigger alerts.
- **⚠️ Remediation actions**: Auto-remediation can modify or delete resources. Test thoroughly before enabling.
- **⚠️ False positives**: Some rules have known false positive scenarios. Review findings before taking action.

## 🔧 Technical Limitations

### Azure Limitations
- **Region availability**: Not all services are available in all regions. Verify service availability for Northern Europe.
- **Quota limits**: Default quotas may be too low for production. Request increases proactively.
- **API rate limits**: Terraform operations can hit rate limits during large deployments. Use `-parallelism` flag to reduce concurrency.

### AWS Limitations
- **Service limits**: Even basic services have quotas (e.g., VPC limit, NAT Gateway limit). Check AWS Service Quotas.
- **eu-north-1 availability**: Some newer services may not be available in Stockholm region. Check service regional availability.
- **Eventual consistency**: AWS resources can take time to propagate (especially IAM). Add wait time if needed.

### Terraform Limitations
- **Provider versions**: Pinning provider versions prevents unexpected breaking changes. Always specify version constraints.
- **State locking timeout**: Default timeout is 10 minutes. Long-running operations may fail with lock timeout.
- **Import limitations**: Not all resource types support import. Some must be manually created in Terraform.

## 🌍 Multi-Cloud Considerations

### Architectural Warnings
- **⚠️ Cross-cloud dependencies**: Avoid creating dependencies between Azure and AWS resources. Keep them isolated.
- **⚠️ Cost comparison**: Don't assume same services cost the same on different clouds. Always compare.
- **⚠️ Skill requirements**: Multi-cloud increases complexity. Ensure team has expertise in both platforms.

### Operational Overhead
- **⚠️ Two sets of tools**: Maintain expertise in Azure CLI/PowerShell AND AWS CLI.
- **⚠️ Separate billing**: Track costs separately per cloud provider. Consolidated view requires additional tooling.
- **⚠️ Different support models**: Azure and AWS have different support tier structures and SLAs.

## 📋 Pre-Deployment Checklist

Before deploying infrastructure, verify:

- [ ] Azure subscription has sufficient permissions (Contributor + User Access Administrator)
- [ ] AWS account has sufficient permissions (AdministratorAccess or specific IAM role)
- [ ] Budget alerts are configured in both Azure and AWS
- [ ] `.gitignore` includes `*.tfstate`, `*.tfvars`, `.terraform/`
- [ ] Remote state backend is initialized (S3 + DynamoDB for AWS, Storage Account for Azure)
- [ ] Service principal/IAM role for CI/CD is configured with minimal permissions
- [ ] Backup and disaster recovery plan is documented
- [ ] Team members have reviewed this WARNINGS.md file
- [ ] Cost estimates have been calculated and approved
- [ ] Security scanning (tfsec, Checkov) has been run on Terraform code

## 🆘 Emergency Contacts and Procedures

### In Case of Cost Spike
1. Check Azure Cost Management and AWS Cost Explorer immediately
2. Identify the expensive resource
3. Evaluate if it can be stopped/deleted safely
4. Update budget alerts to prevent recurrence

### In Case of Security Incident
1. Review [SECURITY.md](SECURITY.md) for security policy
2. Rotate compromised credentials immediately (Azure Key Vault secrets, AWS Secrets Manager)
3. Check Azure Activity Logs and AWS CloudTrail for unauthorized access
4. Enable MFA if not already enabled
5. Document incident for post-mortem

### In Case of Service Outage
1. Check Azure Status page: https://status.azure.com/
2. Check AWS Status page: https://status.aws.amazon.com/
3. Verify if issue is localized to your resources or a platform-wide outage
4. Review Azure Monitor alerts and AWS CloudWatch metrics
5. Follow incident response procedures

## 📚 Additional Resources

- [Azure Cost Management Best Practices](https://docs.microsoft.com/azure/cost-management-billing/costs/)
- [AWS Cost Optimization](https://aws.amazon.com/aws-cost-management/)
- [Terraform State Management Best Practices](https://www.terraform.io/docs/language/state/)
- [Azure Security Best Practices](https://docs.microsoft.com/azure/security/)
- [AWS Security Best Practices](https://aws.amazon.com/security/)

---

## 🎓 Learning from Mistakes

> *"The best way to avoid making mistakes is to learn from the mistakes others have made"*

Common mistakes we've seen (and made ourselves):

1. **Forgetting to enable deletion protection** on production resources → accidental resource deletion
2. **Not setting up budget alerts before deployment** → surprise $5,000 bill
3. **Exposing storage accounts to the internet** → security audit finding
4. **Using static IPs in firewall rules** → blocked access after IP change
5. **Not testing disaster recovery procedures** → chaos during actual incident
6. **Ignoring deprecation warnings** → broken deployments after provider updates
7. **Over-privileging service principals** → security vulnerability
8. **Not monitoring log retention costs** → unexpected storage costs
9. **Deploying to wrong region** → high data transfer costs
10. **Not reading this WARNINGS.md file** → all of the above 😅

---

**Remember**: Infrastructure as Code is powerful but not foolproof. Always review, always test, always backup.

*Last updated: 2025-11-15*
