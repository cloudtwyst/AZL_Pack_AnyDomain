# Upgrading the Pack Version

This playbook covers how to upgrade a customer's platform repo from one pack
version to the next. It applies to both minor upgrades (v1.0 → v1.1) and
patch upgrades (v1.0.0 → v1.0.1).

> **Breaking changes (major version bumps)** follow a separate process.
> Each major release includes a `playbooks/migrate-vX-to-vY.md` migration guide.
> Never skip major-version migration steps.

---

## When to upgrade

Upgrade when:
- A new policy is available in the pack that the customer wants.
- A bug fix in the pack affects the customer's configuration.
- The customer's `packVersion` constraint does not cover the latest release.
- You are responding to an upstream EPAC change that requires a template update.

Check the pack's `CHANGELOG.md` before upgrading to understand the scope of changes.

---

## Step 1 — Review the changelog

Read the `CHANGELOG.md` entries for every version between the customer's current
version and the target version. Identify:

- New optional fields added to `customer-config.yaml` (additive; safe to ignore initially).
- New templates that will be rendered (review before applying).
- Changed default values that might affect rendered output.
- Any deprecated fields (removed in a future major).

---

## Step 2 — Update the pack version constraint

In the customer's `customer-config.yaml`, update:

```yaml
packVersion: ">=1.0.0,<2.0.0"   # old
packVersion: ">=1.1.0,<2.0.0"   # new (example: upgrading to 1.1)
```

Commit this change to a feature branch:

```bash
git checkout -b upgrade/pack-v1.1
```

---

## Step 3 — Re-render

Pull the latest pack source (update your local `azure-solution-pack` clone or
update the version reference however your team manages the pack):

```pwsh
cd path/to/azure-solution-pack
git pull origin main
git checkout v1.1.0   # pin to the release tag
```

Then re-render the customer repo:

```pwsh
solpack render --config ./customer-config.yaml --repo-path . --pack-root path/to/azure-solution-pack
```

---

## Step 4 — Review the diff

```bash
git diff
```

Expected changes for a minor upgrade:
- New policy JSONC files in `Definitions/policyDefinitions/`.
- Updated initiative JSONC files in `Definitions/policySetDefinitions/`.
- Updated workflow templates in `.github/workflows/`.
- Updated `CLAUDE.md`.

Unexpected changes that need manual review:
- Changes to `terraform/main.tf` (Terraform changes need `terraform plan` before merging).
- Changes to `Definitions/policyAssignments/` (policy scope changes need EPAC plan before merging).

---

## Step 5 — Run EPAC plan on dev

Before raising a PR, verify the policy changes are as expected:

```pwsh
Build-DeploymentPlans.ps1 -PacEnvironmentSelector epac-dev `
    -DefinitionsRootFolder ./Definitions `
    -OutputFolder ./Output
```

Review `Output/` carefully. In particular:
- New policies should appear as `New` not `Change`.
- Existing assignments should not show unexpected scope changes.
- No policies owned by other repos (other `pacOwnerId`) should be affected.

---

## Step 6 — Raise a PR

Raise the PR targeting `main`. The CI pipeline will:
1. Validate the schema (`Test-SolpackConfig`).
2. Run the EPAC plan job (if configured).

PR description should include:
- Pack version change (old → new).
- Summary of new policies or changed templates.
- Link to the pack `CHANGELOG.md`.

---

## Step 7 — Deploy

After PR merge, the standard EPAC pipelines handle deployment:
- `epac-nonprod.yml` fires automatically.
- `epac-prod.yml` requires manual approval.

No `solpack deploy` is needed for an upgrade — only for initial onboarding.

---

## v1.0 → v1.0.1 example (patch: bug fix)

This example shows the minimal steps for a patch upgrade.

**What changed:** `Invoke-TemplateRender` idempotency fix — second render
no longer rewrites unchanged files.

1. Update `packVersion: ">=1.0.0,<2.0.0"` → `">=1.0.1,<2.0.0"` (no change needed; constraint already covers 1.0.1).
2. Pull latest pack.
3. Run `solpack render`.
4. `git diff` shows 0 changes (the fix is in the CLI, not in rendered output).
5. Raise a PR anyway to record the pack version acknowledgement.

**Migration note:** None required. Patch releases are always backwards-compatible.

---

## Rollback

If the upgrade causes unexpected compliance failures:

1. Revert the `packVersion` change in `customer-config.yaml`.
2. Re-run `solpack render` with the old pack version.
3. Raise a PR to revert.

Because EPAC uses `desiredStateStrategy: ownedOnly` (default), rolling back
the assignment templates will simply stop managing the new policies — it will
not delete pre-existing policies from other owners.

---

## Notes for major-version upgrades

Major versions (`v1.0 → v2.0`) may:
- Remove or rename fields in `customer-config.yaml`.
- Change the management group naming convention.
- Change the Terraform state backend path.

These require a separate migration playbook shipped with the major release.
Never apply a major-version pack update without reading the migration guide first.
