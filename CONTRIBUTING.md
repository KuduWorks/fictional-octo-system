# Contributing to Fictional Octo System

> *"Because managing multi-cloud infrastructure is better together"* 🐙🤝

Thank you for your interest in contributing to Fictional Octo System! This document provides guidelines and instructions for contributing to our multi-cloud infrastructure repository.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Guidelines](#coding-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)

## Code of Conduct

This project adheres to the Contributor Covenant [Code of Conduct](CODE_OF_CONDUCT.md).  By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title** describing the issue
- **Detailed description** of the problem
- **Steps to reproduce** the behavior
- **Expected vs. actual behavior**
- **Environment details** (OS, Terraform version, cloud provider)
- **Terraform/script output** (sanitized of secrets!)
- **Relevant log files** (again, no secrets please!)

### 💡 Suggesting Enhancements

Enhancement suggestions are welcome! Please include:

- **Use case description** - Why is this needed?
- **Proposed solution** - How should it work?
- **Alternatives considered** - What other approaches did you think about?
- **Impact assessment** - Which cloud providers does this affect?

### 📝 Improving Documentation

Documentation improvements are always appreciated:

- Fix typos or clarify existing docs
- Add examples or use cases
- Update outdated information
- Translate documentation (future)
- Add diagrams or visual aids

### 🔧 Contributing Code

Code contributions can include:

- New Terraform modules for Azure/AWS/GCP
- Automation scripts (Bash, PowerShell, Python)
- CI/CD workflow improvements
- Security enhancements
- Performance optimizations
- Bug fixes

## Getting Started

### Prerequisites

Before contributing, ensure you have:

1. **Cloud Provider CLIs:**
   - Azure CLI (`az`)
   - AWS CLI (`aws`)
   - Google Cloud CLI (`gcloud`)

2. **Development Tools:**
   - Terraform >= 1.3. 0
   - Git
   - Code editor (VS Code recommended)
   - `terraform-docs` (for documentation generation)

3. **Cloud Access:**
   - Test/development subscriptions (NOT production!)
   - Appropriate IAM permissions for testing
   - Budget alerts configured (seriously, set these up first)

### Local Development Setup

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/fictional-octo-system.git
   cd fictional-octo-system
   ```

2. **Configure cloud authentication:**
   ```bash
   # Azure
   az login
   az account set --subscription "your-dev-subscription"
   
   # AWS
   aws configure
   aws sts get-caller-identity  # Verify authentication
   
   # GCP
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project YOUR-DEV-PROJECT
   ```

3. **Install pre-commit hooks** (recommended):
   ```bash
   # Install pre-commit if not already installed
   pip install pre-commit
   
   # Install git hooks
   pre-commit install
   ```

## Development Workflow

### 1. Create a Feature Branch

Always create a new branch for your work:

```bash
git checkout -b feature/descriptive-name
# OR
git checkout -b fix/issue-description
# OR
git checkout -b docs/what-you-are-documenting
```

**Branch Naming Convention:**
- `feature/` - New features or enhancements
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions or modifications

### 2. Make Your Changes

- Keep changes focused and atomic
- Test thoroughly in a development environment
- Update documentation alongside code changes
- Add comments for complex logic
- Follow the coding guidelines below

### 3. Test Your Changes

Before committing, ensure:

```bash
# Format Terraform code
terraform fmt -recursive

# Validate Terraform syntax
cd path/to/your/module
terraform init
terraform validate

# Run a plan (don't apply in prod!)
terraform plan

# For shell scripts, check syntax
shellcheck your-script.sh

# For PowerShell scripts
pwsh -File your-script.ps1 -WhatIf
```

### 4. Commit Your Changes

Follow our [commit message guidelines](#commit-message-guidelines):

```bash
git add .
git commit -m "feat(azure): add network security group module"
```

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub. 

## Coding Guidelines

### Terraform Standards

1. **Formatting:**
   - Always run `terraform fmt` before committing
   - Use 2-space indentation
   - Follow HashiCorp's style guide

2. **Naming Conventions:**
   - Use lowercase with underscores: `resource_group_name`
   - Be descriptive: `vm_automation_rg` not `rg1`
   - For Azure, use the [naming convention module](deployments/azure/modules/naming-convention/)

3.  **Variable Definitions:**
   ```hcl
   variable "example_var" {
     description = "Clear description of what this variable does"
     type        = string
     default     = "sensible-default"
     
     validation {
       condition     = length(var.example_var) > 0
       error_message = "The example_var cannot be empty."
     }
   }
   ```

4. **Resource Organization:**
   - Group related resources together
   - Use locals for computed values
   - Separate concerns into different files (e.g., `monitoring.tf`, `networking.tf`)

5. **Modules:**
   - Create reusable modules for repeated patterns
   - Document module inputs/outputs
   - Include examples in module README

6. **Security:**
   - Never hardcode secrets or credentials
   - Use data sources for sensitive values
   - Implement least-privilege access
   - Enable encryption by default

### Shell Script Standards (Bash)

```bash
#!/usr/bin/env bash
# Description: What this script does
# Usage: ./script.sh [arguments]

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Use meaningful variable names
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/config. conf"

# Add error handling
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Use functions for reusable code
main() {
    # Script logic here
    echo "Doing something useful..."
}

main "$@"
```

### PowerShell Script Standards

```powershell
<#
.SYNOPSIS
    Brief description of what the script does
.DESCRIPTION
    Detailed description
.EXAMPLE
    .\script.ps1 -Parameter "value"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$RequiredParameter
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try {
    # Script logic here
    Write-Host "Doing something useful..."
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
```

### Documentation Standards

1. **README Files:**
   - Include overview, prerequisites, quick start
   - Provide configuration examples
   - Add troubleshooting section
   - Include cost estimates where applicable

2. **Inline Comments:**
   - Explain WHY, not WHAT
   - Document non-obvious behavior
   - Add references to documentation when applicable

3. **Module Documentation:**
   - Use `terraform-docs` to generate documentation
   - Include usage examples
   - Document all inputs and outputs

## Commit Message Guidelines

We follow the [Conventional Commits](https://www.conventionalcommits. org/) specification:

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Scopes

- `azure`: Azure-specific changes
- `aws`: AWS-specific changes
- `gcp`: GCP-specific changes
- `terraform`: General Terraform changes
- `ci`: CI/CD pipeline changes
- `scripts`: Shell/PowerShell scripts

### Examples

```bash
feat(azure): add Key Vault RBAC module

Implements Key Vault deployment with modern RBAC authorization
instead of legacy access policies.  Includes purge protection
and network restrictions. 

Closes #123

---

fix(aws): correct Stockholm region in SCP policy

The region control SCP was referencing eu-west-1 instead of
eu-north-1 (Stockholm). 

---

docs(gcp): update Workload Identity setup guide

Added troubleshooting section for common authentication errors. 
```

## Pull Request Process

### Before Submitting

- [ ] Run `terraform fmt -recursive`
- [ ] Run `terraform validate` on affected modules
- [ ] Test changes in development environment
- [ ] Update documentation
- [ ] Add/update examples if applicable
- [ ] Check for sensitive data in commits
- [ ] Ensure CI/CD checks pass

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Cloud Provider(s)
- [ ] Azure
- [ ] AWS
- [ ] GCP
- [ ] Multi-cloud

## Testing
Describe how you tested these changes

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No sensitive data in commits
- [ ] Tests pass locally

## Additional Context
Any additional information, screenshots, or context
```

### Review Process

1. **Automated Checks:**
   - Terraform formatting validation
   - Syntax validation
   - Security scanning (if configured)

2. **Manual Review:**
   - Code quality and style
   - Security best practices
   - Documentation completeness
   - Test coverage

3. **Approval:**
   - At least one maintainer approval required
   - All discussions resolved
   - CI/CD checks passing

4. **Merge:**
   - Squash and merge (default)
   - Rebase and merge (for feature branches)
   - Maintainers will merge approved PRs

## Testing Guidelines

### Terraform Testing

1. **Validation:**
   ```bash
   terraform init
   terraform validate
   terraform fmt -check
   ```

2. **Planning:**
   ```bash
   terraform plan -out=plan.tfplan
   # Review the plan carefully
   ```

3. **Apply in Dev:**
   ```bash
   # NEVER test directly in production!
   terraform apply plan.tfplan
   ```

4. **Cleanup:**
   ```bash
   # Always clean up test resources
   terraform destroy
   ```

### Multi-Cloud Testing

When changes affect multiple clouds:

1. Test each cloud provider independently
2.  Verify cross-cloud configurations
3. Check authentication flows (OIDC/Workload Identity)
4. Validate cost implications

### Cost Awareness

- Set up budget alerts before testing
- Use smallest instance sizes for testing
- Clean up resources immediately after testing
- Consider using cost estimation tools:
  ```bash
  terraform plan -out=plan.tfplan
  # Use terraform cost estimation tools
  ```

## Security Considerations

### Do NOT Include

- ❌ Secrets, passwords, or API keys
- ❌ Private keys or certificates
- ❌ Real subscription IDs or account numbers
- ❌ Personal email addresses (use examples)
- ❌ Internal company information

### Always Include

- ✅ Encryption by default
- ✅ Least-privilege access
- ✅ Network restrictions
- ✅ Input validation
- ✅ Security best practices documentation

### Secret Management

- Use variable files (`. tfvars`) - NEVER commit these
- Reference Azure Key Vault, AWS Secrets Manager, or GCP Secret Manager
- Use environment variables for CI/CD
- Implement secret rotation

## Questions or Need Help?

- 💬 Open a [Discussion](../../discussions) for general questions
- 🐛 Create an [Issue](../../issues) for bugs or feature requests
- 📧 Contact maintainers (see repository owners)
- 📚 Review existing documentation and examples

## Recognition

Contributors will be:
- Listed in release notes
- Recognized in the project README
- Thanked profusely by the maintainers ☕

---

## Additional Resources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure Naming Conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [GCP Best Practices](https://cloud.google.com/docs/enterprise/best-practices-for-enterprise-organizations)

---

**Thank you for contributing to Fictional Octo System! ** 🐙🎉

*"Together we can make multi-cloud infrastructure less painful, one pull request at a time."*
