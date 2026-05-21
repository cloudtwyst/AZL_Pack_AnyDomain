# Changelog

All notable changes to this project will be documented in this file.

Semver: MAJOR.MINOR.PATCH — see `CLAUDE.md` for bump rules.

## [Unreleased]

### Added

**W1 — Schema + validator**
- `schemas/customer-config.schema.json` — JSON Schema draft-07 covering all 9 top-level sections of customer-config.yaml
- `schemas/policy-metadata.schema.json` — required metadata for every policy JSONC
- `solpack/private/ConvertFrom-ConfigYaml.ps1` — YAML parser wrapper (requires `powershell-yaml`)
- `solpack/private/Assert-SemanticRules.ps1` — 7 semantic checks beyond schema (placeholder GUIDs, mismatched frameworks, missing prod gate, etc.)
- `solpack/public/Test-SolpackConfig.ps1` — `Test-SolpackConfig` cmdlet with `-PassThru` and `-TreatWarningsAsErrors`
- Test fixtures: `tests/fixtures/minimal`, `tests/fixtures/healthcare`, `tests/fixtures/finance`

**W2 — Terraform modules**
- `terraform-modules/remote-state-bootstrap/` — bootstrap storage account for Terraform state
- `terraform-modules/management-groups/` — CAF management group hierarchy (root/platform/landingzones/corp/online/sandbox/decommissioned)
- `terraform-modules/monitoring-backbone/` — Log Analytics workspace + optional Event Hub
- `terraform-modules/service-principals/` — EPAC build/deploy SPs with OIDC federation (no client secrets)
- `terraform-modules/sentinel/` — Sentinel Log Analytics onboarding
- `terraform-modules/private-dns-zones/` — 11 default PaaS private DNS zones with VNet links

**W3 — Policy catalog**
- 11 policy definitions across monitoring, tagging, identity, networking, data-protection, compute categories
- 4 initiative bundles: `baseline-all-customers`, `industry-healthcare`, `framework-hipaa`, `framework-cis-azure-2.0`
- `policy-catalog/assignment-templates/root-baseline.jsonc` — EPAC assignment template with `{{TOKEN}}` placeholders

**W4 — solpack CLI**
- `solpack/private/Resolve-PackRoot.ps1` — pack root auto-detection
- `solpack/private/Get-SubstitutionMap.ps1` — `{{TOKEN}}` map; PAC_OWNER_ID from deterministic MD5 GUID
- `solpack/private/Invoke-TemplateRender.ps1` — idempotent `{{PLACEHOLDER}}` template renderer
- `solpack/private/Copy-PolicyDefinitions.ps1` — selective policy catalog copy based on config
- `solpack/public/New-SolpackCustomer.ps1` — `solpack init`
- `solpack/public/Build-SolpackRepo.ps1` — `solpack render` (idempotent)
- `solpack/public/Invoke-SolpackDeploy.ps1` — `solpack deploy` (9 phases)
- `solpack/public/Export-SolpackHandover.ps1` — `solpack handover`

**W5 — Workflow + docs templates**
- `workflow-templates/epac-dev.yml.tmpl`, `epac-nonprod.yml.tmpl`, `epac-prod.yml.tmpl`, `sync-upstream.yml.tmpl`
- `docs-templates/handover-runbook.md.tmpl`, `approved-azure-services.md.tmpl`, `approved-patterns.md.tmpl`, `controls-development-process.md.tmpl`, `security-baseline-per-service.md.tmpl`, `service-request-issue.md.tmpl`

**W6 — Onboarding playbook**
- `playbooks/onboarding-2-to-4-weeks.md` — 20-day checklist covering discovery, foundation deploy, policy pipelines, and handover

**W7 — Test suite + CI**
- `tests/unit/` — 41 Pester tests covering validator, substitution map, template renderer, and render idempotency
- `.github/workflows/ci.yml` — 4-job CI: Pester, PSScriptAnalyzer, `terraform validate`, tflint
- `.tflint.hcl` — azurerm plugin configuration
- `tests/e2e/README.md` — e2e test specification (Terratest; implementation deferred to v1.1)

### Fixed
- `Test-SolpackConfig`: semantic checks now skipped when schema validation fails (prevents null-reference on structurally invalid configs)
- All idempotent write paths normalize trailing whitespace before comparison to prevent spurious rewrites

### Decisions
- D1: JSON Schema draft-07 (PS7 `Test-Json -Schema` compatibility)
- D2: Terraform azurerm ~> 4.0 / azuread ~> 2.50 for foundation modules
- D3: `{{PLACEHOLDER}}` string replacement as template engine; loops in PS helper functions
- D4: `powershell-yaml` module for YAML parsing
