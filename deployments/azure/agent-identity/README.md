# Entra Agentic Identity

> *"Your AI agent is not a person. It's also not a shared service account. Please stop treating it like one."* 🤖

This guide walks through the three Microsoft Entra identity models you'll reach for when giving workloads and AI agents their own identity — including the new Agent ID platform with Blueprints, which is what you actually want for anything that calls itself an "agent". Each model is covered via Azure Portal and PowerShell (`Microsoft.Graph` module). Graph API reference links are included where relevant — PowerShell calls Graph under the hood anyway, and we only want the implementation to show up once.

Security is not a section you add at the end. It's woven in from the start, which is also true of this document.

---

## 🚗 The Analogy (Read This First)

Everything in this guide maps to a car. This is intentional. Stick with it.

| Concept | Car world | Entra world |
|---|---|---|
| The workload or agent | The car | Your app, service, or AI agent |
| The road network | Roads, toll routes, restricted zones | Microsoft 365 APIs, Azure resources, Microsoft Graph |
| Identity document | Vehicle registration certificate | **App Registration** (the global definition) |
| The car on the road | The car with its plates, insured and road-legal | **Service Principal / Enterprise App** (per-tenant instance) |
| Permissions | Where you're licensed to drive (motorway, bus lane, private road) | OAuth 2.0 scopes and app roles — what the identity is allowed to call |
| Consent | Someone in authority stamping your logbook | Admin consent — a Global Admin saying "yes, this car may drive here" |
| Fleet spec sheet | Manufacturer's type-approval certificate | **Agent Blueprint** — the template all instances are stamped from |
| MOT / insurance / recall | Annual check, renewal, compulsory recall | **Identity governance** — access reviews, lifecycle, bulk revocation |

Keep this table open in another tab. You're welcome.

---

## 🔑 Certificates — The Only Credential You Should Use

> *"A client secret is a password. Passwords get emailed, end up in `.env` files, live in Slack messages, and get rotated 'next sprint'. Certificates are a commitment."*

There are no exceptions. Not for dev. Not for a quick test. Not for "I'll fix it before prod". Using certificates from day one means you never have to go back and clean up. Here's how to generate one on any platform.

### Windows (PowerShell)

```powershell
# Generate a self-signed cert valid for 1 year
$cert = New-SelfSignedCertificate `
    -Subject "CN=my-daemon-app" `
    -CertStoreLocation "cert:\CurrentUser\My" `
    -KeyExportPolicy Exportable `
    -KeySpec Signature `
    -KeyLength 2048 `
    -KeyAlgorithm RSA `
    -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddYears(1)

# Export the public key (.cer) — this is what you upload to Entra
Export-Certificate -Cert $cert -FilePath ".\my-daemon-app.cer"

# Export the full cert with private key (.pfx) — goes into Key Vault, not into a folder called "certs-backup-final-v2"
$pfxPassword = Read-Host -Prompt "PFX password" -AsSecureString
Export-PfxCertificate -Cert $cert -FilePath ".\my-daemon-app.pfx" -Password $pfxPassword

Write-Host "Thumbprint: $($cert.Thumbprint)"
Write-Host "Upload my-daemon-app.cer to Entra. Store my-daemon-app.pfx in Azure Key Vault."
```

### macOS / Linux (PowerShell + OpenSSL)

OpenSSL ships with macOS. On Linux: `sudo apt install openssl`. PowerShell itself: `brew install --cask powershell` on macOS.

```powershell
# From pwsh — these invoke the system openssl binary
& openssl req -x509 -newkey rsa:2048 -keyout my-daemon-app.key `
    -out my-daemon-app.pem -days 365 -nodes -subj "/CN=my-daemon-app"

# Convert PEM to DER (.cer) for Entra upload
& openssl x509 -outform der -in my-daemon-app.pem -out my-daemon-app.cer

# Bundle to PFX for Key Vault storage
& openssl pkcs12 -export -out my-daemon-app.pfx -inkey my-daemon-app.key -in my-daemon-app.pem

Write-Host "Upload my-daemon-app.cer to Entra. Store my-daemon-app.pfx in Key Vault."
Remove-Item my-daemon-app.key  # Private key should only live inside the pfx from here on
```

### Commercial CA (DigiCert and others)

For customer-facing workloads, regulated environments, or where your security policy mandates a trusted chain, use a commercial certificate authority rather than self-signed.

1. Log in to [DigiCert CertCentral](https://www.digicert.com/certcentral/) — or your org's preferred CA (Sectigo, GlobalSign, Entrust, or an on-prem AD CS hierarchy)
2. Request a **Client Authentication** certificate
   - Common Name: match your application's display name (e.g. `my-daemon-app`)
   - Key usage: Digital Signature, Key Encipherment
3. Complete domain / organisation validation per your cert profile
4. Download the issued certificate in **PEM** format
5. Convert for Entra upload: `openssl x509 -outform der -in issued.pem -out upload-to-entra.cer`
6. Store the private key and chain PFX in **Azure Key Vault** — not on a developer's laptop, not in SharePoint

> Your organisation may already have an enterprise CA via AD Certificate Services. Check with your PKI team before buying external certs — you might be paying for one you forgot you had.

### Upload the .cer to an App Registration or Agent Identity

**Portal:** App Registration or Agent Identity → **Certificates & secrets** → **Certificates** → **Upload certificate** → select `.cer` → add a description → **Add**

The PowerShell upload step is embedded in each model's implementation section below.

---

## 🏠 Model 1 — App Registration + Service Principal (Single-Tenant)

> *Your car. Your country. One set of plates.*

You register the car in your home country (your Entra tenant). You get a registration certificate (**App Registration**) — a global definition of what the vehicle is and what it's allowed to do. The moment it hits the road in your country, it becomes a physical, trackable car (**Service Principal** / **Enterprise App**) — the actual identity that authenticates, holds permissions, and shows up in sign-in logs.

**When to use this:** A background daemon, scheduled script, or automation that calls Microsoft Graph (or any Entra-protected API) entirely within your own tenant. Think: an email digest bot, a SharePoint archival service, an IAM reporting tool. If it lives in your tenant and only drives on your roads, this is the model.

**Security baseline before you start:**
- **Certificates only** — client secrets are not permitted in any environment, including development. See the [Certificate Credentials](#-certificates--the-only-credential-you-should-use) section for generation steps.
- Apply **least-privilege scopes** — if it only needs to read users, don't give it `Directory.ReadWrite.All`
- Enable **Conditional Access for workload identities** (Entra ID P1) so you can enforce location and risk policies on the service principal, not just on humans

---

### Azure Portal

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com)
2. Navigate to **Identity** → **Applications** → **App registrations** → **New registration**
3. Set a display name (e.g. `my-daemon-app`) — `AzureADMyOrg` for single-tenant
4. Click **Register**
5. Note the **Application (client) ID** and **Directory (tenant) ID** — you'll need these
6. Add permissions: **API permissions** → **Add a permission** → **Microsoft Graph** → select your scopes → **Grant admin consent**
7. Add credentials: **Certificates & secrets** → **Upload certificate** → select your `.cer` file (see the [Certificate Credentials](#-certificates--the-only-credential-you-should-use) section for generation steps)

The Service Principal is created automatically in **Enterprise applications** when you register the app. Magic, but the reproducible kind.

---

### PowerShell

```powershell
# Connect with the scopes needed to create applications
Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All"

# Create the App Registration
$app = New-MgApplication -DisplayName "my-daemon-app" -SignInAudience "AzureADMyOrg"

Write-Host "App (client) ID: $($app.AppId)"
Write-Host "Object ID:       $($app.Id)"

# Create the Service Principal (the car on the road)
$sp = New-MgServicePrincipal -AppId $app.AppId

Write-Host "Service Principal ID: $($sp.Id)"

# Upload a certificate credential — generate the .cer first (see Certificate Credentials section above)
$certBytes  = [System.IO.File]::ReadAllBytes(".\my-daemon-app.cer")
$certBase64 = [Convert]::ToBase64String($certBytes)

$keyCredential = @{
    KeyCredentials = @(
        @{
            Type        = "AsymmetricX509Cert"
            Usage       = "Verify"
            Key         = $certBase64
            DisplayName = "my-daemon-app-cert-$(Get-Date -Format 'yyyy-MM')"
            EndDateTime = (Get-Date).AddYears(1).ToString("o")
        }
    )
}
Update-MgApplication -ApplicationId $app.Id -BodyParameter $keyCredential

Write-Host "Certificate uploaded. Authenticate using your .pfx + thumbprint. No secrets, ever."
```

> **Note:** The legacy `AzureAD` module is deprecated and will stop working. Use `Microsoft.Graph` (`Install-Module Microsoft.Graph`). Your future self will thank you.

---

## 🌍 Model 2 — Multi-Tenant App

> *Your car. Multiple countries. Each country still stamps your permit.*

Same vehicle — you built one app — but you want it to drive in other people's countries (other Entra tenants). You apply for an **international driving permit**: the App Registration gets `signInAudience: AzureADMultipleOrgs`, and when an admin in a customer tenant consents, a **new Service Principal** is stamped into their tenant from your global app definition. One registration certificate; many local instances.

**When to use this:** An ISV SaaS product, a shared tooling agent distributed to partner or customer tenants, or a multi-customer monitoring solution. If the car needs to cross borders, you need the permit.

**Security baseline:**
- Every customer tenant must perform **admin consent** — you cannot skip this step and you should not want to
- Define **verified publisher** status on your app to build trust signals in the consent UI
- Request only the permissions your app genuinely needs — customers (and their security teams) *will* read the consent screen
- Consider **app-only permissions** (`application` type) for daemons vs. delegated permissions for user-context scenarios

---

### Azure Portal

1. In **App registrations**, open your app → **Authentication**
2. Under **Supported account types**, select **Accounts in any organizational directory (Any Microsoft Entra ID tenant — Multitenant)**
3. Save
4. Share your app's consent URL with customer tenant admins:
   ```
   https://login.microsoftonline.com/common/adminconsent?client_id=<your-app-client-id>
   ```
5. When a customer admin consents, a Service Principal appears in their **Enterprise applications** — visible in their Entra admin center, auditable, revocable

---

### PowerShell

```powershell
Connect-MgGraph -Scopes "Application.ReadWrite.All"

# Flip to multi-tenant — one line, surprisingly consequential
Update-MgApplication -ApplicationId "<object-id>" -SignInAudience "AzureADMultipleOrgs"

# Verify
$app = Get-MgApplication -ApplicationId "<object-id>"
Write-Host "Sign-in audience: $($app.SignInAudience)"

# To inspect Service Principals that have been created in your home tenant
# (each representing consent in a customer tenant, if multi-tenant app is homed here)
Get-MgServicePrincipal -Filter "appId eq '<your-app-client-id>'" |
    Select-Object DisplayName, Id, AppId
```

---

## 🏭 Model 3 — Entra Agent ID + Blueprints (The Fleet Model)

> *You don't hand a car factory worker a blank logbook and say "figure it out". You give them a type-approval certificate, a build spec, and a recall mechanism.*

This is **Microsoft Entra Agent ID** — purpose-built identity for AI agents. The key insight is that AI agents are categorically different from traditional app workloads: they make dynamic decisions, adapt behaviour, operate autonomously, and increasingly talk to *other* agents. A shared App Registration was never built to govern that. Agent ID was.

**The Blueprint pattern:**
- An **Agent Identity Blueprint** is the type-approval certificate / build spec. It defines the identity template: permissions, governance policies, Conditional Access rules, owner/sponsor assignments.
- An **Agent Identity** is an individual car stamped from that spec. It inherits everything from the Blueprint but is its own isolated, auditable, revocable instance.
- Kill a Blueprint, and you can disable *every agent instance stamped from it* in a single operation. Try doing that with thirty service principals and a spreadsheet.

**When to use this:** Any AI agent — Copilot agents, AutoGen workers, MCP-connected agents, autonomous operations agents. If it reasons, decides, and acts without a human in the loop on every call, it needs Agent ID.

**Security baseline (pay attention — this one is more consequential):**
- AI agents are targets for **prompt injection** — malicious instructions embedded in data processed by the agent. Network-level filtering via Global Secure Access can detect and block these
- Agents with broad permissions and autonomous decision-making are high-value targets. Apply **least-privilege at Blueprint level** so all instances start correctly scoped
- Assign a **human sponsor** per blueprint — Entra enforces this. Orphaned agents with no owner are a governance failure waiting to become an incident
- Enable **Identity Protection for agents** (Entra ID P2) — real-time risk detection for anomalous agent behaviour feeds directly into Conditional Access

---

### Azure Portal

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com)
2. Navigate to **Identity** → **Agent ID** → **Blueprints** → **New blueprint**
3. Set a display name (e.g. `invoice-processing-agent`), description, and assign a **sponsor** (mandatory — this is the human accountable for this class of agents)
4. Configure permissions — same Graph/API permission model as App Registrations, but applied at the Blueprint level
5. Save the Blueprint → note the **Blueprint ID**
6. From the Blueprint, select **Create agent identity** — this stamps a new instance from the spec
7. Each agent instance gets its own Object ID, credential, and sign-in logs entry
8. View all instances under **Agent ID** → **Agent identities** — filter by Blueprint to see the full fleet

---

### PowerShell

> **Note:** Auto-generated typed cmdlets for `AgentIdentity` resources (`New-MgAgentIdentity` etc.) may not yet be available in the Microsoft.Graph module even though the Graph API endpoint is GA. Use `Invoke-MgGraphRequest` as shown below — it calls the same endpoint and works today.

```powershell
Connect-MgGraph -Scopes "AgentIdentity.ReadWrite.All"

# --- Create a Blueprint ---
$blueprintBody = @{
    displayName = "invoice-processing-agent"
    description = "Blueprint for invoice processing agents. Stamp responsibly."
    sponsors    = @(
        @{ "@odata.type" = "#microsoft.graph.user"; id = "<sponsor-user-object-id>" }
    )
} | ConvertTo-Json -Depth 5

$blueprint = Invoke-MgGraphRequest -Method POST `
    -Uri "https://graph.microsoft.com/v1.0/agentIdentityBlueprints" `
    -Body $blueprintBody `
    -ContentType "application/json"

Write-Host "Blueprint ID: $($blueprint.id)"

# --- Stamp an agent identity from the Blueprint ---
$agentBody = @{
    displayName         = "invoice-agent-prod-01"
    agentIdentityBlueprintId = $blueprint.id
} | ConvertTo-Json -Depth 3

$agent = Invoke-MgGraphRequest -Method POST `
    -Uri "https://graph.microsoft.com/v1.0/agentIdentities" `
    -Body $agentBody `
    -ContentType "application/json"

Write-Host "Agent Identity ID: $($agent.id)"
Write-Host "Agent App ID:      $($agent.appId)"

# --- Add a certificate credential to the agent identity ---
# Generate the .cer first — see the Certificate Credentials section above
$certBytes  = [System.IO.File]::ReadAllBytes(".\my-agent.cer")
$certBase64 = [Convert]::ToBase64String($certBytes)

$keyBody = @{
    keyCredential = @{
        type        = "AsymmetricX509Cert"
        usage       = "Verify"
        key         = $certBase64
        displayName = "agent-cert-$(Get-Date -Format 'yyyy-MM')"
        endDateTime = (Get-Date).AddYears(1).ToString("o")
    }
    proof = "<proof-of-possession JWT — see addKey MS Docs for generation steps>"
} | ConvertTo-Json -Depth 3

Invoke-MgGraphRequest -Method POST `
    -Uri "https://graph.microsoft.com/v1.0/agentIdentities/$($agent.id)/addKey" `
    -Body $keyBody `
    -ContentType "application/json"

Write-Host "Certificate uploaded to agent identity $($agent.id). No secrets used."
```

> Graph API endpoints used by the PowerShell examples above: `POST /agentIdentityBlueprints`, `POST /agentIdentities`, `GET /agentIdentityBlueprints/{id}/agentIdentities`, `PATCH /agentIdentityBlueprints/{id}`, and `POST /agentIdentities/{id}/addKey`. Full reference: [Microsoft Graph API — agentIdentity resource](https://learn.microsoft.com/en-us/graph/api/resources/agentidentity).

---

## 🔒 Security — Baked In From the Start

Not a checklist you run post-deployment. This is architecture.

### Credential hygiene

| Approach | Verdict |
|---|---|
| Certificate credential | ✅ Required. Every environment. See the [Certificate Credentials](#-certificates--the-only-credential-you-should-use) section. |
| Managed Identity as FIC | ✅ Best for Azure-hosted workloads — no credential to manage or leak |
| Workload Identity Federation | ✅ Best for non-Azure compute (GitHub Actions, Kubernetes, etc.) |
| Client secret, any environment | 🚨 No. Not for prod. Not for staging. Not for dev. Not "just this once". |
| Shared credential of any kind, stored in a repo | 🚨 Absolutely not. We've seen where this ends. |

### Conditional Access for agents

Apply Conditional Access policies to service principals and agent identities — not just users. Use `signInRiskLevel`, location conditions, and custom security attributes to gate access at runtime.

- Requires **Entra ID P1** for service principals
- Requires **Entra ID P1** for agent identities (Blueprint-level policy inheritance means you configure once, applies to all instances automatically)

```powershell
# Check existing CA policies scoped to workload identities
Connect-MgGraph -Scopes "Policy.Read.All"
Get-MgIdentityConditionalAccessPolicy |
    Where-Object { $_.Conditions.ClientApplications } |
    Select-Object DisplayName, State
```

### Identity Protection for agents

Entra ID Protection detects anomalous agent behaviour — unusual authentication patterns, leaked credentials, high-risk sign-in locations — and feeds risk signals into Conditional Access for real-time enforcement.

- Requires **Entra ID P2**
- Agents with elevated risk can be automatically blocked until investigated

### Network controls — prompt injection defence and traffic governance

Two options depending on whether you're deploying native Azure tooling or running a mixed / non-Azure environment.

#### Option A — Microsoft Global Secure Access (native Azure)

Global Secure Access applies web categorisation and threat-intelligence filtering to agent traffic, including **prompt injection detection** at the network layer — malicious instructions smuggled into data the agent processes.

- Configure via **Global Secure Access** → **Traffic forwarding** → agent profile
- Requires **Microsoft Entra Internet Access** (included in Microsoft Entra Suite)
- Agent network activity appears alongside identity events in Entra sign-in logs — one pane, no pivoting

#### Option B — Tailscale (third-party zero-trust overlay)

If you're not deploying the full Entra Suite, or if your agents run in non-Azure environments where GSA coverage is incomplete, [Tailscale](https://tailscale.com) is a well-regarded alternative.

Tailscale builds a private WireGuard mesh across your infrastructure. Agents communicate only within that mesh and are unreachable from the public internet regardless of where they're deployed.

- **Reduces attack surface**: agent calls to internal APIs or databases go over the mesh, not the public internet
- **Entra integration**: Tailscale supports [Azure AD / Entra ID as an identity provider](https://tailscale.com/kb/1087/azure-ad) — agents authenticate to the mesh using their Entra identity
- **Prompt injection at the network layer**: Tailscale itself does not do content filtering. Pair it with an egress proxy (Squid, a commercial SWG, or similar) for content inspection
- **When to prefer Tailscale over GSA**: multi-cloud or on-prem agent deployments, dev environments, teams without Entra Suite licensing

> GSA and Tailscale aren't mutually exclusive. Some teams use Tailscale for agent-to-agent mesh traffic and GSA for agent-to-internet egress policy.

---

## 🏛️ Governance — Preventing Agent Sprawl

> *"Agent sprawl" is what happens when every team ships agents without IT oversight, temporary agents run in production indefinitely, and nobody knows who owns what. It ends badly.*

Agent sprawl is the AI equivalent of shadow IT, except the shadow IT can place purchasing orders or delete infrastructure. Microsoft's guidance is explicit: treat agent governance as a first-class concern, not an afterthought.

### Blueprint-level policy inheritance

Configure Conditional Access rules, permissions, and governance policies on the **Blueprint** — not on each agent individually. Every current and future instance inherits them automatically. When you need to change a policy, change it once on the Blueprint. When you need to kill the fleet, disable the Blueprint. This is the point.

### Mandatory sponsorship

Every Blueprint must have an assigned **sponsor** — a named human accountable for that class of agents. Entra enforces this. No sponsor = the agent doesn't get provisioned. This prevents the "nobody knows who owns it" class of incident.

### Lifecycle management with ID Governance

- **Access packages**: time-bound permissions for agent identities — agents expire unless explicitly renewed
- **Access reviews**: periodic reviews of service principals and agent identities with privileged roles; automated removal if reviewers don't respond
- **Orphaned identity detection**: Entra ID Governance flags agent identities with no assigned sponsor or owner

```powershell
# Export your full agent identity inventory — useful for governance audits
Connect-MgGraph -Scopes "AgentIdentity.Read.All"

$agents = Invoke-MgGraphRequest -Method GET `
    -Uri "https://graph.microsoft.com/v1.0/agentIdentities?`$select=id,displayName,createdDateTime,accountEnabled,agentIdentityBlueprintId"

$agents.value | ForEach-Object {
    [PSCustomObject]@{
        Name        = $_.displayName
        Id          = $_.id
        BlueprintId = $_.agentIdentityBlueprintId
        Created     = $_.createdDateTime
        Enabled     = $_.accountEnabled
    }
} | Format-Table -AutoSize

# Spot-check for agents with no blueprint (potential unmanaged workloads)
$agents.value | Where-Object { -not $_.agentIdentityBlueprintId } |
    Select-Object displayName, id, createdDateTime
```

### Audit logs

All agent authentication and actions are logged in Entra ID sign-in logs and audit logs — viewable in the Entra admin center or via PowerShell:

```powershell
# Query agent sign-in logs
Connect-MgGraph -Scopes "AuditLog.Read.All"

$logs = Invoke-MgGraphRequest -Method GET `
    -Uri "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$filter=signInIdentifierType eq 'agentIdentity'"

$logs.value | Select-Object createdDateTime, appDisplayName, ipAddress,
    @{N='Status'; E={$_.status.errorCode}} | Format-Table -AutoSize
```

---

## 🛡️ Microsoft Purview — Protecting Data That Agents Touch

> *"You've secured the identity. You've governed the lifecycle. Now ask: what is the agent actually doing with the data it can reach?"*

Securing agent identity controls *who can act*. Microsoft Purview controls *what happens to the data they access*. For AI agents with access to sensitive content — financial records, customer PII, HR documents — this is the layer that prevents exfiltration, over-sharing, and compliance violations.

### Information Protection — sensitivity labels

Microsoft Purview Information Protection classifies and labels documents, emails, and SharePoint content by sensitivity. When an agent reads, summarises, copies, or generates content:

- **Labels travel with the data**: a document labelled `Confidential` carries that label even if the agent copies or forwards it
- **Encryption enforced at label level**: agents without appropriate rights cannot decrypt content above their clearance, even with valid Graph API access to the container
- Pair sensitivity label conditions with **Conditional Access policies** (Entra ID P2 + Purview) to block agent access to content above their permission level at runtime

### Data Loss Prevention (DLP) policies for AI workloads

Purview DLP policies detect and block sensitive data (PII, payment card numbers, health records) in:
- Microsoft 365 services accessed by agents via delegated or app-only Graph permissions
- Microsoft Copilot Studio and Azure OpenAI integrations (via Purview AI Hub)
- Teams messages, SharePoint files, Exchange emails generated or touched by agents

**Create a DLP policy scoped to AI activity:**
1. Open the [Microsoft Purview compliance portal](https://compliance.microsoft.com)
2. Navigate to **Data loss prevention** → **Policies** → **Create policy**
3. Choose a template (Financial data, GDPR, HIPAA, etc.) or build custom
4. Under **Locations**, enable **Microsoft 365 Copilot and AI activities**
5. Add conditions: **Content contains** → sensitive information types relevant to your data
6. Set action to **Audit** first, then **Block** once you've validated the policy scope — walking before running is acceptable here

### Purview AI Hub — visibility into agent data activity

Purview AI Hub provides a centralised view of AI activity across your tenant: which agents accessed what data, what content was sent to LLMs, and where potential policy violations occurred.

- Navigate to **Microsoft Purview** → **AI Hub**
- Surfaces interactions between agents (Copilot, custom agents, Azure OpenAI) and sensitive content
- Feeds into DLP enforcement and compliance reporting — useful evidence trail for audits

### Communication Compliance — for agents that generate content

If your agents generate text sent to users (emails, Teams messages, reports), Communication Compliance policies can scan agent-generated output for policy violations — regulatory language, sensitive data leakage, or content that should not leave the org — and route violations for human review before anything bad happens.

### When to prioritise Purview coverage

| Agent type | Purview priority |
|---|---|
| Agent reads only public or non-sensitive data | Low — identity controls sufficient |
| Agent accesses SharePoint or Exchange with business data | **High** — DLP + sensitivity labels |
| Agent generates content sent to users or external parties | **High** — Communication Compliance + DLP |
| Agent processes PII, health, or payment data | **Critical** — DLP + Audit + legal hold |
| Agent provisioned with an M365 user account (mailbox, Teams) | **Critical** — full Purview coverage required |

> **Licensing:** Purview Information Protection and DLP are included in **Microsoft 365 E3**. AI Hub, Communication Compliance, and advanced DLP features require **Microsoft 365 E5 Compliance** or the **Microsoft Purview add-on**.

---

## 🧭 Decision Guide — Which Model Should I Use?

| Scenario | Recommended model | Why |
|---|---|---|
| Background script/daemon in your own tenant | App Registration + Service Principal (single-tenant) | Simple, well-understood, no consent complexity |
| ISV SaaS product deployed to customer tenants | Multi-tenant App Registration | One global app definition, per-tenant Service Principal created on consent |
| Single AI agent with bounded, known behaviour | Entra Agent ID (no Blueprint required for one-offs) | Agent-specific governance constructs, proper lifecycle, sponsor enforcement |
| Fleet of similar AI agents (e.g. 10 invoice-processing agents) | Agent ID + Blueprint | Centrally managed spec, bulk disable, consistent policy inheritance across all instances |
| AI agent needing M365 mailbox / Teams presence | Agent ID + Agent's user account | User account pairs 1:1 with agent identity; use only when the agent must access mailbox/calendar/Teams |
| Autonomous agent making consequential decisions (infra, purchasing) | Agent ID + Blueprint + ID Governance access packages | Time-bound, reviewed, auditable. If it can delete things, it needs a leash. |

> One rule of thumb: if you'd be nervous explaining to an auditor how you manage its lifecycle, use a Blueprint.

---

## 💳 Licensing Quick Reference

| Feature | Minimum licence |
|---|---|
| App Registrations + Service Principals | Microsoft Entra ID Free |
| Entra Agent ID (agent identities + blueprints) | Microsoft Entra ID Free |
| Conditional Access for workload / agent identities | Microsoft Entra ID P1 |
| Identity Protection for agents (risk-based blocking) | Microsoft Entra ID P2 |
| ID Governance for agents (access reviews, lifecycle, access packages) | Microsoft Entra ID P1 |
| Agent network controls + prompt injection defence | Microsoft Entra Internet Access (included in Entra Suite) |
| Tailscale zero-trust overlay (third-party alternative) | Tailscale free tier or Teams/Business plan — see [tailscale.com/pricing](https://tailscale.com/pricing) |
| Microsoft Agent 365 integration (M365 services and workflows) | Microsoft Agent 365 licence per user |
| Microsoft Purview DLP + Information Protection | Microsoft 365 E3 |
| Purview AI Hub, Communication Compliance, advanced DLP | Microsoft 365 E5 Compliance or Purview add-on |
| Full security stack | Microsoft 365 E5 (covers P1 + P2 + Entra Suite + Purview E5) |

---

## 📚 References

All links valid as of May 2026.

- [What are workload identities?](https://learn.microsoft.com/en-us/entra/workload-id/workload-identities-overview)
- [What is Microsoft Entra Agent ID?](https://learn.microsoft.com/en-us/entra/agent-id/what-is-microsoft-entra-agent-id)
- [What are agent identities?](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/what-are-agent-identities)
- [Agent identity blueprints](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-blueprint)
- [Microsoft Entra security for AI overview](https://learn.microsoft.com/en-us/entra/agent-id/security-for-ai-overview)
- [Identity governance for agents](https://learn.microsoft.com/en-us/entra/id-governance/agent-id-governance-overview)
- [Conditional Access for agents](https://learn.microsoft.com/en-us/entra/identity/conditional-access/agent-id)
- [Identity Protection for agents](https://learn.microsoft.com/en-us/entra/id-protection/concept-risky-agents)
- [Network controls for agents (Global Secure Access)](https://learn.microsoft.com/en-us/entra/global-secure-access/concept-secure-web-ai-gateway-agents)
- [Sign-in and audit logs for agents](https://learn.microsoft.com/en-us/entra/agent-id/sign-in-audit-logs-agents)
- [Microsoft Graph API — agentIdentity resource](https://learn.microsoft.com/en-us/graph/api/resources/agentidentity)
- [Microsoft Graph API — addKey (application)](https://learn.microsoft.com/en-us/graph/api/application-addkey)
- [What is managed identities for Azure resources?](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview)
- [Workload identity federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)
- [Microsoft Purview Information Protection](https://learn.microsoft.com/en-us/purview/information-protection)
- [Microsoft Purview Data Loss Prevention](https://learn.microsoft.com/en-us/purview/dlp-learn-about-dlp)
- [Microsoft Purview AI Hub](https://learn.microsoft.com/en-us/purview/ai-microsoft-purview)
- [Tailscale — Azure AD identity provider](https://tailscale.com/kb/1087/azure-ad)
