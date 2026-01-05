# Fictional Octo System 🐙

> *"Because manually clicking through three different cloud portals is a form of self-inflicted DevOps torture"*

Multi-cloud Terraform infrastructure that actually works (most of the time). Choose your cloud poison, we've got modules for all the major players.

## Table of Contents

- [Quick Links](#quick-links)
- [Features](#features)
- [Getting Started](#getting-started)
- [Contributing](#contributing)

## 🚀 Quick Links (a.k.a. Pick Your Cloud Adventure)

- **Azure** 🔵: [deployments/azure/](deployments/azure/) — app registration, Key Vault, policies, communication services, reporting *(because Microsoft loves acronyms)*
- **AWS** 🟠: [deployments/aws/](deployments/aws/) — state bootstrap, budgets, SCPs, FinOps Lambda, CloudTrail, GitHub OIDC *(Jeff Bezos's side project)*
- **GCP** 🔴: [deployments/gcp/](deployments/gcp/) — bootstrap, workload identity, security, cost management *(Google's "we can cloud too" offering)*
- **Terraform root**: [terraform/](terraform/) — shared state backend and VNet examples *(the fun one with all the jokes)*


## ✨ Features (a.k.a. What This Thing Actually Does)

### 🔐 Security & Compliance
> *"Because security through obscurity is not a feature, it's a bug waiting to happen"*

- **Preventive enforcement**: Service Control Policies (AWS) and Azure Policies with Deny effects *(the "no, you can't do that" of cloud governance)*
- **OIDC authentication**: GitHub Actions integration without long-lived secrets *(because math > sticky notes with passwords)*
- **Encryption baselines**: S3, EBS, RDS, DynamoDB encryption requirements *(encrypting all the things)*
- **Region controls**: Geographic restrictions (Stockholm for AWS, configurable for Azure) *(sorry, Singapore)*
- **Organization-level CloudTrail**: Centralized audit logging across AWS accounts *(for when the auditors come knocking)*
- **Key management**: Azure Key Vault and AWS KMS/Secrets Manager patterns *(where secrets go to be safely managed)*

### 💰 Cost Management
> *"Keeping your cloud bill from becoming a mortgage payment"*

- **Budget monitoring**: Multi-tier alerting for AWS and GCP with email notifications *(your early warning system)*
- **FinOps automation**: Lambda functions for cost optimization and reporting *(making finance teams slightly less grumpy)*
- **SNS notifications**: Real-time budget alerts *(before the CFO finds out you deployed 47 NAT Gateways)*
- **Cost allocation**: Tagging strategies and reporting templates *(so you know who to blame)*

### 🏗️ Infrastructure as Code
> *"Because clicking is for mice, not engineers"*

- **Multi-cloud modules**: Reusable Terraform for Azure, AWS, and GCP *(DRY principles apply to clouds too)*
- *🎯 Getting Started

### Prerequisites

- Azure CLI, AWS CLI, or gcloud CLI *(pick your poison... or install all three like a masochist)*
- Terraform >= 1.3.0 *(because we like our HCL modern)*
- Appropriate cloud permissions *(a.k.a. someone actually trusts you with production)* ☕
- Coffee *(optional but highly recommended)*
- A sense of humor *(for when `terraform destroy` doesn't ask for confirmation)*

### Quick Start

**Azure** *(the "works on my machine" cloud)*:
```bash
az login  # pray the browser popup doesn't get lost
cd deployments/azure/key-vault  # or app-registration
terraform init && terraform apply
```

**AWS** *(now with 437% more IAM confusion)*:
```bash
aws configure  # paste those keys you definitely shouldn't email yourself
cd deployments/aws/terraform-state-bootstrap
terraform init && terraform apply
```

**GCP** *(where every product has been renamed twice)*:
```bash
gcloud auth application-default login  # longest command ever
cd deployments/gcp/bootstrap/state-storage
terraform init && terraform apply
```

📖 🤝 Contributing

> *"Code reviews are like opinions: everyone has one, and yours is probably wrong"* 😄

1. Read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) *(be nice, don't be a jerk)*
2. Create a feature branch *(not called `fix-stuff` or `asdfasdf`)*
3. Make your changes *(with actual commit messages, not "updated thing")*
4. Run `terraform fmt` *(because tabs vs spaces is so last decade)*
5. Open a PR *(bonus points if you include why, not just what)*

**Pro tip**: PRs with emoji in the description get reviewed 37% faster* 🚀

<sub>*Not scientifically proven, but feels true</sub>

---

## 📜 The Fine Print

**License**: MIT *(do whatever you want, just don't blame me)*  
**Security**: [SECURITY.md](SECURITY.md) *(found a bug? Tell us before Twitter does)*  
**Status**: Work in progress *(a.k.a. it works on my machine)*

*Built with ☕, 😤, and an unhealthy amount of Stack Overflow*r for detailed setup.

## Contributing

Read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), then open a PR.

---

**License**: MIT | **Security**: [SECURITY.md](SECURITY.md)
