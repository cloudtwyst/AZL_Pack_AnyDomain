# Azure Secure Landing Zone — Solution Pack

A reusable, config-driven pack that onboards any Azure tenant to a secure landing
zone — EPAC policy pipeline + DINE-driven monitoring + secure lifecycle — in **2–4 weeks**.

One `customer-config.yaml` drives everything: the CLI reads it, validates it, and
renders a customer-specific platform repository ready to deploy.

---

## What's in the box

| Component | Description |
|-----------|-------------|
| `solpack` CLI | PowerShell module: `init`, `validate`, `render`, `deploy`, `handover` |
| Terraform modules | Remote state, management groups, monitoring backbone, service principals, Sentinel, private DNS |
| Policy catalog | 11 policy definitions across 4 initiative bundles (baseline, healthcare, HIPAA, CIS Azure 2.0) |
| Workflow templates | GitHub Actions EPAC pipelines for dev / nonprod / prod + upstream sync |
| Docs templates | Handover runbook, approved services list, security baseline, controls process, issue templates |
| Onboarding playbook | 20-day checklist from kickoff to customer sign-off |
| Upgrade playbook | Step-by-step minor/patch/major version upgrade guide |
| Test suite | 54 Pester unit tests + CI workflow (PSScriptAnalyzer, tflint, terraform validate) |

---

## Prerequisites

| Tool | Minimum version |
|------|----------------|
| PowerShell | 7.0 |
| Terraform | 1.6.0 |
| Azure CLI | latest |
| [EPAC](https://azure.github.io/enterprise-policy-as-code/) | latest (`Install-Module EnterprisePolicyAsCode`) |
| [powershell-yaml](https://github.com/cloudbase/powershell-yaml) | any (`Install-Module powershell-yaml`) |

Optional: `pandoc` for PDF generation in `solpack handover`.

---

## Quick start

### 1. Install the module

```powershell
Import-Module ./solpack/solpack.psm1
```

### 2. Create a customer config

Copy `tests/fixtures/minimal/customer-config.yaml` as a starting point and fill
in your customer's details:

```yaml
schemaVersion: "1.0"
packVersion: ">=0.1.0,<1.0.0"

customer:
  name: "Contoso Healthcare"
  shortCode: "contoso"
  industry: "healthcare"
  primaryContact: "ops@contoso.com"

azure:
  tenantId: "00000000-0000-0000-0000-000000000000"
  # ... see tests/fixtures/healthcare/customer-config.yaml for a full example
```

### 3. Validate

```powershell
Test-SolpackConfig -Path customer-config.yaml
```

### 4. Initialise the customer repo

```powershell
New-SolpackCustomer -ConfigPath customer-config.yaml -RepoPath ./contoso-platform
```

### 5. Deploy

```powershell
cd ./contoso-platform
Invoke-SolpackDeploy -ConfigPath customer-config.yaml
```

The deploy runs 9 phases interactively. Use `-Phase N` to run a single phase:

| Phase | What it does |
|-------|-------------|
| 0 | Bootstrap Terraform remote state |
| 1 | Deploy management group hierarchy |
| 2 | Deploy monitoring backbone (LAW + Event Hub) |
| 3 | EPAC scaffolding on dev environment |
| 4 | Service principals + OIDC federation |
| 5 | GitHub Actions workflows (manual git push) |
| 6 | Assign DINE and baseline policy initiatives |
| 7 | SIEM connection (manual verification) |
| 8 | Generate handover bundle |

### 6. Re-render after config changes

```powershell
Build-SolpackRepo -ConfigPath customer-config.yaml -RepoPath ./contoso-platform
```

Re-running against an unchanged config produces no diff (idempotent).

---

## Repository layout

```
azure-solution-pack/
├── solpack/                    # PowerShell CLI module
│   ├── public/                 # Exported cmdlets
│   └── private/                # Internal helpers
├── terraform-modules/          # Reusable Terraform modules
│   ├── remote-state-bootstrap/
│   ├── management-groups/
│   ├── monitoring-backbone/
│   ├── service-principals/
│   ├── sentinel/
│   └── private-dns-zones/
├── policy-catalog/             # EPAC policy definitions and initiatives
│   ├── definitions/
│   ├── initiatives/
│   └── assignment-templates/
├── workflow-templates/         # GitHub Actions .tmpl files
├── docs-templates/             # Per-customer Markdown .tmpl files
├── schemas/                    # JSON Schema (draft-07) for config validation
├── tests/
│   ├── fixtures/               # minimal / healthcare / finance configs
│   └── unit/                   # Pester tests (54 total)
├── playbooks/                  # Universal how-to guides
│   ├── onboarding-2-to-4-weeks.md
│   └── upgrade-pack-version.md
├── SOLUTION-PACK.md            # Full specification
├── decisions.md                # Architecture decision log
└── CHANGELOG.md
```

---

## Customer repo layout (rendered by `solpack init`)

```
{customer}-platform/
├── terraform/                  # main.tf + terraform.tfvars (generated)
├── Definitions/                # EPAC policy definitions, initiatives, assignments
│   ├── policyDefinitions/
│   ├── policySetDefinitions/
│   └── policyAssignments/
├── .github/
│   ├── workflows/              # Rendered GitHub Actions pipelines
│   └── ISSUE_TEMPLATE/         # Service request + policy proposal templates
├── handover/                   # Generated docs for the customer's team
├── customer-config.yaml        # Source of truth
├── CODEOWNERS                  # Restricts Definitions/ and handover/ to InfoSec
├── CLAUDE.md                   # Per-customer Claude Code brief
└── decisions.md
```

---

## Running the tests

```powershell
Import-Module Pester -MinimumVersion 5.0
$cfg = . ./tests/pester.config.ps1
Invoke-Pester -Configuration $cfg
```

CI runs four jobs on every push: Pester, PSScriptAnalyzer, `terraform validate`,
and tflint. See `.github/workflows/ci.yml`.

---

## Supported configurations

| Config field | Options |
|---|---|
| `azure.managementGroups.layout` | `caf` (default), `flat`, `custom` |
| `monitoring.siem` | `sentinel`, `splunk`, `elastic`, `sumo`, `custom` |
| `monitoring.logAnalytics.topology` | `per-region`, `per-continent`, `global` |
| `policy.desiredStateStrategy` | `ownedOnly` (default), `full` |
| `policy.initiatives.industry` | `healthcare`, `finance`, `public-sector`, `retail` |
| `policy.initiatives.frameworks` | `hipaa`, `iso-27001`, `cis-azure-2.0`, `nist-800-53` |

---

## Versioning

Semver. `customer-config.yaml` pins a version range (e.g. `>=0.1.0,<1.0.0`).
See `playbooks/upgrade-pack-version.md` for the upgrade process and
`CHANGELOG.md` for release notes.

---

## Contributing

1. Read `CLAUDE.md` for working conventions and the 8-workstream discipline.
2. Read `SOLUTION-PACK.md` §6 for the workstream definitions.
3. Every new policy in the catalog must cite a published framework (CIS, PCI, etc.).
4. All changes must pass `PSScriptAnalyzer`, `tflint`, `terraform validate`, and Pester before merging.
5. Record architecture decisions in `decisions.md`.
