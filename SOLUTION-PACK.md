# Azure Secure Landing Zone — Solution Pack

A reusable, **customer-agnostic** pack that stands up the architecture from the
uploaded diagrams (EPAC + DINE-driven monitoring + secure solution lifecycle) in any
customer's Azure tenant.

**Target onboarding time: 2–4 weeks.** Either your team or the customer's team can
run the deployment from the same artifacts.

> **For Claude Code:** read this file plus `CLAUDE.md`, then ask which workstream
> from §6 to start. Don't start coding the platform-modules library before §3
> (architecture) and §5 (config schema) are locked.

---

## 1. What the pack contains (and what it isn't)

### What it is
A versioned, GitHub-distributed repository containing:

- A **library** of Terraform modules covering the foundation (MGs, monitoring,
  service principals, OIDC federation, etc.).
- A **catalog** of Azure Policy definitions, initiatives, and assignment templates
  in the EPAC layout, tagged by industry and control framework (CIS, PCI-DSS,
  HIPAA, ISO 27001, NIST 800-53, Azure Security Benchmark).
- A **CLI / wizard** (`solpack` — PowerShell-based to match EPAC) that turns a
  customer config file into a deployable repo.
- **Onboarding playbook** with day-by-day tasks for the 2–4 week target.
- A **handover bundle template** (docs, runbooks, RACI) generated per customer.

### What it isn't
- Not a Terraform "ALZ replacement". It complements [Azure Landing Zones (CAF)](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
  by gluing EPAC + monitoring + lifecycle around the LZ, and can deploy on top of
  an existing CAF LZ.
- Not a one-click SaaS. Customers still need an Azure tenant, an identity with
  the right permissions, and somebody who can answer the questions in `customer-config.yaml`.
- Not a policy authoring tool. It uses upstream EPAC for that.

---

## 2. Source diagrams — what each contributes

A faithful summary of what was extracted from each uploaded diagram, so the pack
is grounded in your source material.

### 2.1 `azure-monitor-dine-siem.vsdx` → **monitoring-backbone module**
DINE policy assignment + system-assigned managed identity that auto-creates
diagnostic settings on every in-scope resource, sending Resource Logs to a
Log Analytics Workspace ("per continent") **and** to an Event Hub Namespace
("per region"). Same pattern for Activity Logs. SIEM consumes via Event Hub
Data Reader role.

### 2.2 `azure-security-controls-process.vsdx` (2 pages) → **lifecycle docs**
- Page 1 — *Consuming* controls: dev flow checks approved services list, approved
  patterns, secure IaC templates, RBAC defs, policy initiatives, threat model,
  SAST/DAST. Infosec is a control gate.
- Page 2 — *Producing* controls: continuous SCF improvement loop, controls dev/test,
  proof of effectiveness, final approvals, automated deployment to prod, outputs
  the Azure Security Baseline per service.

### 2.3 `epac-explanations.vsdx` (7 pages) → **policy-catalog + epac scaffolding**
- Branch model & pipelines (feature → dev plan → PR → main → prod deploy).
- Scripts and roles: `Build-DeploymentPlans.ps1` (Resource Policy Reader),
  `Deploy-PolicyPlan.ps1` (Resource Policy Contributor), `Deploy-RolesPlan.ps1`
  (User Access Administrator).
- Fork/sync model: upstream EPAC ← customer fork ← work repo, kept in sync with
  `Sync-Repo.ps1`.
- `desiredState.strategy`: `"full"` deletes policies without a `pacOwnerId`,
  `"ownedOnly"` only deletes policies with this repo's `pacOwnerId`, never touches
  policies owned by other repos. `excludedScopes` carves out scopes owned elsewhere.

### 2.4 `epac-github-flow.drawio` / `epac-release-flow.drawio` → **workflow templates**
7-step GitHub Actions release flow (feature branch → EPAC-DEV deploy → PR →
main → PROD/NON-PROD deploy → role deploy) parameterised for any environment.

---

## 3. Reference architecture (per customer)

What every customer gets when the pack is deployed at minimum. Modules in §4
are toggleable around this baseline.

```
GitHub Org (yours OR customer's — both supported)
└── {customer}-platform/                ← created by `solpack init`
    ├── terraform/                       ← foundation modules selected per config
    ├── Definitions/                     ← EPAC policy definitions, initiatives, assignments
    ├── .github/workflows/               ← rendered from templates per environment
    ├── customer-config.yaml             ← THE source of truth (see §5)
    ├── decisions.md                     ← human-readable trail of choices
    ├── CLAUDE.md                        ← per-customer Claude Code brief
    └── handover/                        ← generated docs for the customer's team

Azure (customer tenant)
├── Tenant Root Group
│   └── {prefix}-root                   ← prefix from customer-config.yaml
│       ├── platform/         (connectivity, identity, management subs)
│       ├── landingzones/     (corp, online)
│       ├── sandbox/
│       └── decommissioned/
│
├── EPAC environments (mapped to MGs in globalSetting.jsonc):
│   ├── epac-dev      → sandbox MG
│   ├── epac-nonprod  → landingzones/corp MG
│   └── epac-prod     → root MG
│
└── Monitoring backbone
    ├── Log Analytics workspace(s)       — per region OR per "continent" OR one global
    ├── Event Hub Namespace               — per region, auto-inflate capped
    ├── DINE initiative: "diag-settings-to-eh-and-law" (assigned at root MG)
    └── SIEM ingestion path (Sentinel | Splunk | Elastic | Sumo | custom)
```

---

## 4. Pack repository layout

```
azure-solution-pack/                        ← the product, versioned with semver
├── README.md
├── SOLUTION-PACK.md                        ← this file
├── CLAUDE.md
├── VERSION                                 ← semver tag, e.g. 1.0.0
├── CHANGELOG.md
│
├── solpack/                                ← the CLI
│   ├── solpack.psm1                        ← PowerShell module
│   ├── public/
│   │   ├── New-SolpackCustomer.ps1         ← `solpack init`
│   │   ├── Test-SolpackConfig.ps1          ← `solpack validate`
│   │   ├── Build-SolpackRepo.ps1           ← `solpack render`
│   │   ├── Invoke-SolpackDeploy.ps1        ← `solpack deploy`
│   │   └── Export-SolpackHandover.ps1      ← `solpack handover`
│   └── private/                            ← helpers, not exported
│
├── terraform-modules/                      ← reusable foundation modules
│   ├── management-groups/                  ← MG hierarchy from config
│   ├── monitoring-backbone/                ← LAW + EH topology from config
│   ├── service-principals/                 ← EPAC SPs + GitHub OIDC federation
│   ├── remote-state-bootstrap/             ← the chicken-and-egg SA for tf state
│   ├── sentinel/                           ← optional, enabled if SIEM=sentinel
│   ├── private-dns-zones/                  ← optional, for PaaS private endpoints
│   └── _examples/                          ← worked examples per module
│
├── policy-catalog/                         ← EPAC-formatted JSONC, tagged
│   ├── definitions/
│   │   ├── tagging/
│   │   ├── networking/
│   │   ├── monitoring/                     ← incl. the DINE initiative from §2.1
│   │   ├── identity/
│   │   ├── data-protection/
│   │   ├── compute/
│   │   └── _metadata.jsonc                 ← tags: industry, framework, severity
│   ├── initiatives/
│   │   ├── baseline-all-customers/         ← assigned to everyone
│   │   ├── industry-finance/
│   │   ├── industry-healthcare/
│   │   ├── industry-public-sector/
│   │   ├── industry-retail/
│   │   ├── framework-cis-azure-2.0/
│   │   ├── framework-pci-dss-4.0/
│   │   ├── framework-hipaa/
│   │   ├── framework-iso-27001/
│   │   └── framework-nist-800-53/
│   └── assignment-templates/               ← rendered per customer
│
├── workflow-templates/                     ← GitHub Actions templates
│   ├── epac-dev.yml.tmpl
│   ├── epac-nonprod.yml.tmpl
│   ├── epac-prod.yml.tmpl
│   └── sync-upstream.yml.tmpl              ← from epac-explanations p.3
│
├── docs-templates/                         ← per-customer docs (rendered)
│   ├── approved-azure-services.md.tmpl
│   ├── approved-patterns.md.tmpl
│   ├── service-request-issue.md.tmpl
│   ├── security-baseline-per-service.md.tmpl
│   ├── controls-development-process.md.tmpl
│   └── handover-runbook.md.tmpl
│
├── schemas/
│   ├── customer-config.schema.json         ← validates customer-config.yaml
│   └── policy-metadata.schema.json
│
├── playbooks/
│   ├── onboarding-2-to-4-weeks.md          ← see §7
│   ├── operate-day-2.md
│   └── upgrade-pack-version.md
│
└── tests/
    ├── terraform/                          ← terratest or tflint suites
    ├── policy/                             ← EPAC `Confirm-PolicyDefinitions` etc.
    └── e2e/                                ← ephemeral subscription deploy
```

---

## 5. The customer config file — the single source of truth

Every customer is described by **one** YAML file. The CLI reads it, validates it
against `schemas/customer-config.schema.json`, and renders a customer-specific
repo from the templates.

```yaml
# customer-config.yaml
schemaVersion: "1.0"
packVersion: ">=1.0.0,<2.0.0"

customer:
  name: "Contoso Healthcare"
  shortCode: "contoso"            # used in resource names; lowercase, ≤8 chars
  industry: "healthcare"          # → unlocks framework-hipaa initiatives below
  primaryContact: "ops@contoso.com"

deployment:
  mode: "self-service"            # "managed" (your team) | "self-service" (theirs)
  github:
    org: "contoso-platform"
    repoName: "contoso-azure-platform"
    visibility: "private"
  approval:
    nonprod: false                # gate non-prod merges? (default false)
    prod: true                    # always true; cannot be disabled

azure:
  tenantId: "00000000-0000-0000-0000-000000000000"
  managementSubscriptionId: "..."  # subscription for LAW/EH backbone
  regions:
    primary: "westeurope"
    secondary: ["northeurope"]
  managementGroups:
    layout: "caf"                  # "caf" (default) | "flat" | "custom"
    rootPrefix: "contoso"
    customTree: null               # required if layout=custom; see schema

monitoring:
  siem: "sentinel"                # sentinel | splunk | elastic | sumo | custom
  logAnalytics:
    topology: "per-continent"     # per-region | per-continent | global
  eventHub:
    enabled: true                 # auto-false if siem=sentinel & customer agrees
    maxThroughputUnits: 10

policy:
  pacOwnerIdSeed: "contoso-2025"  # deterministic GUID derivation
  desiredStateStrategy: "ownedOnly"  # ownedOnly | full
  initiatives:
    baseline: true                 # always true; locked
    industry: ["healthcare"]       # from {finance, healthcare, public-sector, retail}
    frameworks:                    # multi-select; intersection becomes the assignment
      - "hipaa"
      - "iso-27001"
      - "cis-azure-2.0"
    exclusions:                    # per-customer carve-outs
      - scope: "/providers/Microsoft.Management/managementGroups/contoso-research"
        reason: "Research MG governed by university policy"

lifecycle:
  enableServiceRequestFlow: true   # creates the GH issue templates from p.1 of controls process
  infosecReviewers:                # CODEOWNERS for approved-* paths
    - "@contoso/infosec-team"
  approvedServicesSeed: "minimal"  # minimal | broad | custom

handover:
  generateRunbooks: true
  trainingSessions: 2              # included in onboarding plan
```

A `solpack validate customer-config.yaml` runs schema validation **plus** semantic
checks (e.g. `desiredStateStrategy: full` with `industry: healthcare` warns about
the risk of nuking pre-existing HIPAA controls).

---

## 6. Workstreams (parallelisable)

These are independent enough that you can build them in parallel once §3 and §5
are locked. Each is its own slice for Claude Code.

| # | Workstream | Owner-skill | Deliverable | Blocks onboarding? |
|---|------------|-------------|-------------|---------------------|
| W1 | **Config schema + validator** | JSON Schema, PowerShell | `customer-config.schema.json` + `Test-SolpackConfig.ps1` | Yes — everything else reads it |
| W2 | **Terraform module library** | Terraform, azurerm/azuread | Modules under `terraform-modules/` with examples and tests | Yes |
| W3 | **Policy catalog + tagging** | Azure Policy, EPAC | Catalog under `policy-catalog/` with framework metadata | Yes |
| W4 | **CLI (`solpack`)** | PowerShell modules | Working `solpack init/validate/render/deploy/handover` | Yes |
| W5 | **Workflow + docs templates** | GitHub Actions, Markdown templating | `.tmpl` files that render cleanly per config | No (can ship in v1.1) |
| W6 | **Onboarding playbook** | Process / writing | `playbooks/onboarding-2-to-4-weeks.md` (see §7) | No |
| W7 | **Test suite** | Terratest, EPAC test cmdlets | `tests/` runnable per PR + nightly e2e | No for v1.0, yes for v1.1 |
| W8 | **Handover bundle generator** | PowerShell, Pandoc | `Export-SolpackHandover.ps1` produces PDF + Markdown | No for v1.0 |

**Recommended sequence:** W1 → W3 in parallel with W2 → W4 → W5 → W6 → W7 → W8.
W1 must finish before W4 starts. W2 and W3 are independent.

---

## 7. The 2–4 week onboarding playbook (per customer)

The pack ships with this as `playbooks/onboarding-2-to-4-weeks.md`. Here's the
shape; it's filled in during W6.

### Week 1 — Discovery and config
- **Day 1**: kickoff, intro to the pack, walk through `customer-config.yaml`.
- **Days 2–3**: customer (or your team) fills in the config. Open questions tracked.
- **Day 4**: `solpack validate` + design review.
- **Day 5**: customer creates Azure SP for bootstrap, sets up GitHub org.

### Week 2 — Foundation deploy
- **Day 6**: `solpack init` → repo created and committed.
- **Day 7**: Phase 0 (remote-state SA) + Phase 1 (MGs) deployed to customer tenant.
- **Day 8**: Phase 2 (monitoring backbone) deployed.
- **Days 9–10**: Phase 3 (EPAC scaffolding) deployed; trivial test policy proves the pipeline.

### Week 3 — Policy and pipelines
- **Day 11**: Phase 4 (service principals + OIDC) deployed.
- **Day 12**: Phase 5 (workflows) wired up; first end-to-end run on a feature branch.
- **Day 13**: Phase 6 (DINE initiative) assigned; remediation tasks kicked off.
- **Day 14**: Phase 7 (SIEM connection) verified.
- **Day 15**: First remediation cycle complete.

### Week 4 — Lifecycle + handover (buffer)
- **Day 16**: Phase 8 (lifecycle docs) generated; CODEOWNERS active.
- **Day 17**: Training session 1 (operating the pack).
- **Day 18**: Training session 2 (Day-2 ops: incidents, policy changes, upgrades).
- **Day 19**: `solpack handover` produces the bundle.
- **Day 20**: signoff. Customer owns it.

Each day has a numbered checklist that Claude Code walks through. If a day slips,
the buffer in week 4 absorbs it; the playbook flags when slippage threatens the
4-week limit.

---

## 8. Versioning, upgrades, and the "long tail" problem

Once you have N customers running pack v1.0, v1.1 ships. How does customer N
upgrade?

- **Pack uses semver.** `customer-config.yaml` pins a range (e.g. `>=1.0.0,<2.0.0`).
- **Each customer's rendered repo records the pack version** in a top-level file.
- **`solpack upgrade`** in the customer's repo:
  1. Diffs the customer's current rendered files against the new pack version.
  2. Re-renders templates with the customer's existing config.
  3. Produces a PR against the customer's repo with the merge.
- **Breaking changes (major version) require a migration script** in
  `playbooks/upgrade-pack-version.md` — never expect customers to figure it out.

This is the single biggest reason packs fail in the real world: nobody plans for
upgrades. The repo design here (config file + templates + version pin) is
specifically chosen so upgrades are routine.

---

## 9. Multi-tenant / multi-cloud considerations

You said *"any customer and cloud project"*. The pack is **Azure-only** in v1.0
but the layout is designed so AWS/GCP can be added later as siblings to
`terraform-modules/` (e.g. `terraform-modules/aws-foundation/`) with the same
`customer-config.yaml` schema gaining a `cloud:` field.

Don't try to build all three in v1.0. Ship Azure end-to-end, get five customers
onboarded, then add AWS based on what you learned.

---

## 10. Risks specific to building a pack (not a one-off)

| Risk | Mitigation |
|------|------------|
| Pack drifts from EPAC upstream | Pin the EPAC version in `customer-config.yaml`; `Sync-Repo.ps1` flows from pack → customer repos, not customer → pack. |
| One customer's customisation leaks into the pack | All customer-specific code lives in the rendered repo only. Pack is read-only at runtime. |
| Policy catalog grows unboundedly | Define an entry bar: every policy in the catalog must be cited to a published framework (CIS / PCI / etc.). No bespoke policies — those go in customer repos. |
| "Heavy tuning" (your answer) turns every customer into a snowflake | The config schema caps customisation surface area. If a customer needs something not in the schema, it's either (a) a v1.x feature ticket against the pack or (b) lives in their repo as an override, never merged back upstream. |
| Quality regressions between releases | W7 test suite must include an "ephemeral subscription" e2e test that deploys the pack against a real Azure sub every nightly. Without this, breakages will be found by customers. |
| The CLI becomes a parallel universe to Terraform | Keep `solpack` thin: it only does config validation, file rendering, and orchestration. All actual deploys go through `terraform` and EPAC's PowerShell — never reimplement them. |
| Mixed deployment modes (managed vs self-service) drift apart | Both modes share the same `solpack` commands. The only difference is who's at the keyboard. Resist building a separate "managed" tooling track. |

---

## 11. What v1.0 ships with (definition of done)

A pack is **v1.0** when:

1. `solpack init` produces a working customer repo from a valid config.
2. The repo deploys cleanly into an **ephemeral Azure subscription** in CI
   (proves the e2e path).
3. Three reference configs in `tests/fixtures/`: `minimal`, `healthcare`, `finance`.
   All three pass the e2e test.
4. The 2–4 week onboarding playbook has been run against **at least one** real
   customer pilot and the timing held.
5. `playbooks/upgrade-pack-version.md` exists and the v1.0 → v1.0.1 upgrade path
   has been tested.
6. Handover bundle template renders a valid PDF for the pilot customer.

Anything beyond this list is v1.1.

---

## 12. References

- EPAC: <https://github.com/Azure/enterprise-policy-as-code>
- EPAC docs: <https://azure.github.io/enterprise-policy-as-code/>
- Azure Landing Zones (CAF): <https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/>
- Terraform `azurerm` provider: <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs>
- Terratest: <https://terratest.gruntwork.io/>

> Verify these URLs when you start. They were correct at the time this plan was
> written but Microsoft and HashiCorp rename things periodically.
