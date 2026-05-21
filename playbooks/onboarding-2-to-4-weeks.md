# Onboarding Playbook — 2 to 4 Weeks

This playbook is for the engineer (your team or the customer's team) running
`solpack` to onboard a new Azure tenant to the secure landing zone.

**Time budget:** 20 working days (4 weeks). The first 15 days cover the core
work; days 16–20 are buffer and handover.

---

## Before you start

**Required access:**
- Azure: Global Administrator or Owner on the root Management Group (temporary; scoped down post-deploy).
- GitHub: Owner or Admin on the target organisation.
- Local tooling: PowerShell 7+, Terraform ≥ 1.6, Azure CLI, EPAC module (`Install-Module EnterprisePolicyAsCode`), `solpack` module.

**Key artefacts produced:**
- `{customer}-platform` GitHub repository (private).
- Foundation infrastructure (remote state, MGs, monitoring backbone, service principals).
- EPAC policy pipeline (3 environments: dev, nonprod, prod).
- Handover bundle (runbooks, approved services list, security baseline).

---

## Week 1 — Discovery and config

### Day 1 — Kickoff

- [ ] Kick off meeting with customer stakeholders (IT/security lead + platform engineer).
- [ ] Walk through `SOLUTION-PACK.md` §1–§5. Confirm scope.
- [ ] Agree on GitHub organisation name and repository name.
- [ ] Confirm Azure tenant ID, management subscription ID, and primary region.
- [ ] Share a blank `customer-config.yaml` for them to complete offline.

**Deliverable:** Open questions list (GitHub issue in the pack repo or shared doc).

---

### Days 2–3 — Config authoring

- [ ] Customer (or your team) fills in every field of `customer-config.yaml`.
- [ ] Agree on `shortCode` (≤8 chars, lowercase, used in resource names).
- [ ] Agree on `pacOwnerIdSeed` — typically `{shortCode}-{year}`.
- [ ] Choose MG layout: `caf` (default), `flat`, or `custom`.
- [ ] Choose SIEM: `sentinel` (default), `splunk`, `elastic`, `sumo`, or `custom`.
- [ ] Select applicable frameworks: `hipaa`, `iso-27001`, `cis-azure-2.0`, `nist-800-53`.
- [ ] Record open questions; resolve before Day 4.

**Deliverable:** Draft `customer-config.yaml` ready for validation.

---

### Day 4 — Validation and design review

```pwsh
solpack validate path/to/customer-config.yaml
```

- [ ] All schema errors resolved.
- [ ] All semantic warnings reviewed and accepted or resolved.
- [ ] Run `solpack render --dry-run` (or render into a temp dir) to preview the output.
- [ ] Design review with platform team:
  - MG hierarchy diagram approved.
  - Monitoring topology approved.
  - Policy frameworks in scope confirmed.
- [ ] Config committed to a branch in the pack repo for traceability.

**Deliverable:** Signed-off `customer-config.yaml`.

---

### Day 5 — Azure and GitHub pre-work

- [ ] Customer creates a service principal (bootstrap) with Owner on the tenant root
  (used only for Terraform phases 0–2; role is removed post-deploy).
- [ ] Customer creates the GitHub organisation (or confirms the existing one).
- [ ] Store bootstrap SP credentials as GitHub Actions secrets or in a local `.env`
  (never commit them).
- [ ] Confirm Terraform remote state will be bootstrapped manually (Phase 0 is
  the first thing `solpack deploy` runs).

---

## Week 2 — Foundation deploy

### Day 6 — Repo init

```pwsh
solpack init --config path/to/customer-config.yaml --repo-path ./output/{customer}-platform
cd ./output/{customer}-platform
git remote add origin https://github.com/{github_org}/{github_repo}.git
git push -u origin main
```

- [ ] Repo created locally and pushed to GitHub.
- [ ] Branch protection on `main`: require PR + at least 1 approver.
- [ ] GitHub Environments created: `epac-dev`, `epac-nonprod`, `epac-prod`
  (epac-prod must have required reviewers).
- [ ] Verify rendered files match expectations (CLAUDE.md, Definitions/, terraform/).

**Deliverable:** Empty platform repo on GitHub with branch protection.

---

### Day 7 — Phases 0 and 1

```pwsh
solpack deploy --phase 0   # remote state bootstrap
solpack deploy --phase 1   # management groups
```

- [ ] Terraform remote state storage account created (`{shortCode}tfstate`).
- [ ] Management groups created in the customer's tenant.
- [ ] Verify MG hierarchy in the Azure portal.

> **Checkpoint:** If Phase 0 fails, stop. Remote state is the prerequisite for
> everything else. Debug before proceeding.

---

### Day 8 — Phase 2

```pwsh
solpack deploy --phase 2   # monitoring backbone
```

- [ ] Log Analytics workspace deployed.
- [ ] Event Hub namespace + hub deployed (if `eventHub.enabled: true`).
- [ ] Note the LAW workspace ID and Event Hub auth rule resource ID.
- [ ] Update `customer-config.yaml` with the actual workspace and auth rule IDs
  (or set as tfvars outputs).
- [ ] Re-run `solpack render` to push IDs into `Definitions/`.

---

### Days 9–10 — Phase 3

```pwsh
solpack deploy --phase 3   # EPAC dev scaffolding
```

- [ ] EPAC `globalSettings.jsonc` deployed with the three environments.
- [ ] Deploy a trivial test policy (e.g. audit RG missing `Owner` tag) to epac-dev.
- [ ] Verify the policy appears as compliant/non-compliant in the portal.
- [ ] Policy pipeline end-to-end proof: feature branch → epac-dev deploy → PR.

> **Checkpoint:** The test policy must flow through the pipeline successfully
> before proceeding to Phase 4.

---

## Week 3 — Policy and pipelines

### Day 11 — Phase 4

```pwsh
solpack deploy --phase 4   # service principals + OIDC
```

- [ ] `epac-build` SP created with Resource Policy Reader on root MG.
- [ ] `epac-deploy` SP created with Resource Policy Contributor + User Access Administrator.
- [ ] Federated identity credentials created for `epac-dev`, `epac-nonprod`, `epac-prod`.
- [ ] Client IDs added as GitHub Actions secrets:
  - `EPAC_BUILD_CLIENT_ID`
  - `EPAC_DEPLOY_CLIENT_ID`
  - `MGMT_SUBSCRIPTION_ID`

---

### Day 12 — Phase 5

- [ ] Rendered GitHub Actions workflows committed to the customer repo (`main`).
- [ ] Trigger `epac-dev.yml` manually; verify it succeeds with OIDC login.
- [ ] Create a test feature branch, push a small Definitions change, verify
  `epac-dev.yml` fires automatically.
- [ ] Raise a PR; verify it can be merged and `epac-nonprod.yml` + `epac-prod.yml` fire.

**Deliverable:** All three EPAC pipelines green end-to-end.

---

### Day 13 — Phase 6

```pwsh
solpack deploy --phase 6   # baseline initiative assignment
```

- [ ] `baseline-all-customers` initiative assigned to the root MG.
- [ ] Industry and framework initiatives assigned to appropriate MGs.
- [ ] Remediation tasks created for DINE policies (diagnostic settings).
- [ ] Note non-compliant resources; agree remediation timeline with customer.

---

### Day 14 — Phase 7

```pwsh
solpack deploy --phase 7   # SIEM connection
```

- [ ] Sentinel onboarding completed (if `siem: sentinel`).
- [ ] Or SIEM connector configured manually and documented in `decisions.md`.
- [ ] Verify logs flowing from at least one resource type into the SIEM.

---

### Day 15 — First remediation cycle

- [ ] Review compliance dashboard in Defender for Cloud.
- [ ] Pick the top 3 non-compliant controls; raise PRs or remediation tasks.
- [ ] Confirm at least one DINE remediation task ran successfully.
- [ ] Customer team guided through raising their first policy PR end-to-end.

---

## Week 4 — Lifecycle + handover

### Day 16 — Phase 8 / lifecycle

```pwsh
solpack deploy --phase 8
```

- [ ] Handover bundle generated: runbook, approved services, approved patterns,
  security baseline, controls process.
- [ ] CODEOWNERS file active for `Definitions/` and `handover/` paths.
- [ ] Service request issue template live in `.github/ISSUE_TEMPLATE/`.

---

### Day 17 — Training session 1: operating the pack

Topics:
- What `solpack render` does and when to run it.
- How to raise a PR for a policy change (full walkthrough).
- How to read the EPAC deployment plan output.
- How to add a new subscription to a management group.

Duration: 2 hours. Record the session.

---

### Day 18 — Training session 2: Day-2 operations

Topics:
- Upgrading the pack version (`packVersion` in config + `solpack render`).
- Adding a new compliance framework.
- Managing exemptions (`policy.initiatives.exclusions`).
- Rotating nothing (OIDC means no secrets to rotate; confirm understanding).
- Escalation path for incidents.

Duration: 2 hours.

---

### Day 19 — Handover bundle delivery

```pwsh
solpack handover --repo-path ./output/{customer}-platform
```

- [ ] Final bundle generated and reviewed.
- [ ] Pandoc PDF produced (if pandoc installed).
- [ ] Bundle committed to `handover/` in the customer repo.
- [ ] Customer confirms all contacts and escalation paths are correct.

---

### Day 20 — Signoff

- [ ] Customer signs the handover acceptance form (out of scope; use your standard form).
- [ ] Bootstrap SP credentials revoked / Owner role removed from root MG.
- [ ] Pack team no longer has access to the customer tenant (confirm).
- [ ] Customer's platform team confirms they can raise a PR, run the pipeline, and
  merge without pack team assistance.
- [ ] `decisions.md` in the customer repo is complete and up to date.

**Deliverable:** Customer owns the platform. Pack team is in advisory role only.

---

## Slippage guide

| Days lost | Recommended action |
|-----------|-------------------|
| 1–2 | Use Week 4 buffer days. No escalation needed. |
| 3–4 | Compress training sessions; deliver async materials. Notify customer. |
| 5+ | Escalate to engagement lead. Identify the blocker (access, config clarity, Azure quota). |

> The most common blocker is Azure access: the customer's IT team takes 3+ days to
> provision the bootstrap SP. Pre-empt this on Day 5 by confirming the SP exists
> before starting Week 2.

---

## Quick reference: `solpack` commands

| Command | What it does |
|---------|-------------|
| `solpack validate <config>` | Schema + semantic validation |
| `solpack init` | Creates customer repo skeleton |
| `solpack render` | Re-renders all artefacts from config |
| `solpack deploy --phase N` | Runs one deployment phase |
| `solpack deploy` | Runs all phases interactively |
| `solpack handover` | Generates handover bundle |
