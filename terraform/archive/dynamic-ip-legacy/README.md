# Legacy Dynamic IP Wrappers (Disabled)

These scripts previously added/cleaned IP firewall rules for the Terraform state account. They are now **disabled**. Use Terraform with Azure AD/OIDC and `storage_access_method` (managed_identity, private_endpoint, or ip_whitelist) instead.

- State identifiers in these scripts are placeholders only. Do not replace with real values in this public repo.
- Each script exits immediately to prevent accidental use.
- Preferred access: managed identity with federated credential for CI, or `storage_access_method = "private_endpoint"`/`"managed_identity"` for users.

If you truly need to re-enable, coordinate with maintainers, update the placeholders privately, and remove the guard with a review.
