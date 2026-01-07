# AWS IAM Identity Center (sso-entra-id) Deployment Steps

This guide shows how to wire AWS IAM Identity Center to Entra ID as the IdP so users can sign in to AWS (console and CLI) via SSO using their Entra ID credentials.

> This is a public repo. Use placeholders (e.g., `<your-tenant>`, `<your-sso-portal>`, `<your-account-id>`) and store secrets only in secure locations. Do not commit `terraform.tfvars` or credentials.

## 0) Prerequisites
- AWS Organizations enabled; using the management account.
- Choose an IAM Identity Center home region.
- Entra ID admin rights to create an Enterprise App and configure SAML + SCIM.
- Define Entra groups to sync (avoid whole-directory sync).
- Keep a break-glass IAM admin/role in the AWS management account.

## 1) Enable IAM Identity Center
- In the AWS management account, open IAM Identity Center and turn it on in the chosen home region.
- Leave the default (built-in) directory until the external IdP is wired.

## 2) Connect Entra ID via SAML
- In Identity Center, select external identity provider and download the AWS SAML metadata.
- In Entra ID, create an Enterprise App (non-gallery or `AWS IAM Identity Center` if available).
- Upload AWS metadata; set Identifier/Reply URLs from that metadata.
- Set NameID to UPN or email per policy.
- Download Entra SAML metadata and upload it back into Identity Center.

## 3) Enable SCIM provisioning
- In Identity Center, create a SCIM endpoint and token.
- In Entra → Provisioning, set SCIM endpoint URL and token; scope to intended groups; start provisioning.
- Verify attribute mappings: email, givenName, surname, UPN/immutable ID.

## 4) Create permission sets and assignments
- In Identity Center, create permission sets (e.g., `ReadOnly`, `PowerUser`, `Administrator` as needed).
- Assign Entra groups/users to AWS accounts with those permission sets.
- Allow a few minutes for propagation.

## 5) Cutover and pilot checklist
- Export or note intended assignments: Entra group → AWS account → permission set; start with non-production accounts.
- Create a small pilot Entra group to validate SSO, SCIM, and permission sets before broad rollout.
- Ensure at least one admin exists in the target identity source before switching sources; keep a break-glass IAM admin in AWS.
- Limit SCIM scope to the pilot groups during initial sync; expand after success.
- Plan a change window; inform users that cached CLI SSO tokens may need re-login after source or assignment changes.

## 6) Enforce access policies
- In Entra, apply Conditional Access/MFA to the Enterprise App so MFA is enforced centrally.
- When Conditional Access is enforcing MFA for this app, do not additionally require MFA in AWS (for example, IAM user MFA or extra MFA prompts in IAM Identity Center), to avoid redundant prompts and sign-in failures; leave AWS MFA requirements disabled or not configured unless you have a specific, documented exception.

## 7) CLI/IDE SSO usage
- Ensure AWS CLI v2+ is installed.
- Users run `aws configure sso` with:
  - SSO start URL: `https://<your-sso-portal>.awsapps.com/start`
  - SSO region: Identity Center home region
  - Choose account + permission set when prompted
- Test: `aws sts get-caller-identity` and a simple service call (e.g., `aws s3 ls`). IDE AWS toolkits reuse these SSO profiles.

## 8) Rollback and recovery
- Keep the break-glass IAM admin active.
- If SAML/SCIM fails, switch Identity Center identity source back to the built-in directory and fix metadata/claims, then retry.
- After switching identity sources, reassign users/groups that exist in the active source. SCIM/assignments may take a few minutes; users may need to re-run `aws configure sso` to refresh tokens.

## 9) Validation checklist
- Sign in via the SSO portal and confirm role selection works.
- Run `aws sts get-caller-identity` under an SSO profile.
- Verify least-privilege by testing a read-only permission set separately from admin.
- Confirm expected groups are provisioned (and no extra groups leaked) in Identity Center.

## 10) Cost reminders
- IAM Identity Center is offered at no additional cost; downstream charges include STS calls, optional CloudTrail/CloudWatch/S3 logging, AWS Config evaluations, and standard data transfer. Confirm region-specific pricing.
