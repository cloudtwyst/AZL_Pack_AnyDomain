# CLAUDE.md — Building the Azure Solution Pack

This file is read automatically by `claude` (Claude Code) when working in this
repo. It tells Claude how to work on **the pack itself** — not on a customer
deployment. The full spec is in `SOLUTION-PACK.md`.

> **Important context:** This is product code, not customer code. A bug here
> affects every customer who uses it. Treat changes with the discipline of a
> library author, not a sysadmin.

## Project at a glance

We are building a **reusable solution pack** that lets either our team or the
customer's team onboard a new Azure tenant to a secure landing zone (EPAC + DINE
monitoring + secure lifecycle) in **2–4 weeks**. The pack is config-driven —
one `customer-config.yaml` per customer drives the whole render.

The blueprint is `SOLUTION-PACK.md`. Always read it before suggesting changes
that span workstreams.

## Working agreement

1. **Workstream discipline.** `SOLUTION-PACK.md` §6 lists 8 workstreams. Ask
   me which one we're on before generating code. Don't sprawl across workstreams
   in a single PR — they get reviewed separately.

2. **Config schema is the contract.** Any new feature that needs a customer
   choice goes through `customer-config.yaml` first. If you can't express it in
   the schema, the feature isn't designed yet.

3. **Templates render; modules deploy.** Two distinct kinds of files in this repo:
   - **Templates** (`.tmpl`, files under `docs-templates/` and `workflow-templates/`)
     get rendered by the CLI into a customer's repo. Don't put deploy logic in them.
   - **Modules** (`terraform-modules/`) are deployed directly by the customer's
     repo after rendering. Don't put templating syntax in them.
   Don't mix the two.

4. **Backwards compatibility within a major version.** Once a `schemaVersion` is
   shipped, fields can be **added** but never **removed or repurposed** in the
   same major. Breaking changes bump the major. This is non-negotiable —
   customers on v1.0 must be able to upgrade to v1.9 without rewriting their config.

5. **Never store customer data in the pack.** No customer names, tenant IDs,
   subscription IDs, or domain references in commits to this repo. All examples
   use `contoso`, `fabrikam`, GUIDs like `00000000-...`, and example.com domains.

6. **Idempotency is non-negotiable.** Every Terraform module and every CLI
   command must be safe to re-run. The CLI `solpack render` against an existing
   customer repo should produce no diff if config hasn't changed.

7. **The CLI stays thin.** `solpack` does config validation, file rendering,
   and orchestration only. It does NOT reimplement `terraform`, `az`, or
   EPAC's PowerShell scripts. If you're tempted to write `Invoke-AzureCli`
   inside the CLI, stop and shell out instead.

## Repo conventions

- **Module layout**: one folder per logical module under `terraform-modules/`,
  each with `versions.tf`, `main.tf`, `variables.tf`, `outputs.tf`, `README.md`,
  and an `_examples/` sibling showing minimal and full usage.
- **Policy catalog**: every JSONC file under `policy-catalog/` carries the
  metadata fields from `schemas/policy-metadata.schema.json` — `industry[]`,
  `frameworks[]`, `severity`, `references[]`. Without metadata it doesn't ship.
- **Templates**: file extension is the rendered extension plus `.tmpl`
  (e.g. `epac-prod.yml.tmpl` renders to `epac-prod.yml`). Use the same templating
  engine throughout the pack — pick one in W4 and don't mix (recommend PowerShell's
  built-in `ExpandString` for simple cases, or `pwsh`-callable Mustache for
  anything with loops/conditionals).
- **Docs**: under `docs-templates/` (rendered per customer) or `playbooks/`
  (universal). Use kebab-case filenames.
- **Tests**: under `tests/` mirroring the source tree. A module at
  `terraform-modules/management-groups/` has its tests at
  `tests/terraform/management-groups/`.

## Style

- **Terraform** for foundation. Pin `azurerm` and `azuread` provider versions
  in every module's `versions.tf`. Pin Terraform itself to 1.6 or newer.
  Always `terraform fmt` and `terraform validate` before committing. Modules
  must pass `tflint` with the `azurerm` ruleset.
- **PowerShell 7+** for the CLI and for any EPAC-adjacent scripts. Use approved
  verbs. Public cmdlets exported by `solpack.psm1` must have full
  comment-based help (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`).
  Run `PSScriptAnalyzer` clean. No `Write-Host` in libraries — use
  `Write-Verbose` / `Write-Information`.
- **JSONC** for the policy catalog, matching EPAC's format exactly. Don't invent
  new structure; if upstream changes, we change too.
- **YAML** for `customer-config.yaml` and for GitHub Actions workflows. 2-space
  indent. Always quote string values that look like booleans, numbers, or dates.
- **Markdown**: tight, scannable, no marketing language. Tables for option lists.
  Reference-style links allowed for repeated URLs.

## Versioning

- Semver. Files: `VERSION` (machine-readable) + `CHANGELOG.md` (human-readable).
- Major: breaking config or module interface changes. Migration script required.
- Minor: additive features, new modules, new policies. No migration needed.
- Patch: bug fixes, doc fixes, test improvements.
- Tag releases as `v1.2.3` in git. CI builds a release artifact on tag push.

## Verification before merging

Before merging anything to `main`:
1. `tflint` clean on all modified Terraform.
2. `PSScriptAnalyzer` clean on all modified PowerShell.
3. JSON Schema validation passes for all `.jsonc` and `.yaml` files.
4. The e2e test (deploy `tests/fixtures/minimal` to an ephemeral Azure sub) passes.
5. `CHANGELOG.md` updated under the unreleased section.
6. If the change touches `customer-config.schema.json`, the
   `playbooks/upgrade-pack-version.md` is updated with a migration note.

## When in doubt

- Re-read the relevant section of `SOLUTION-PACK.md`.
- Check the source diagrams under `reference/diagrams/`.
- Ask me. A short clarifying question is always better than a long wrong PR.
- For Azure / EPAC API details, search the web — your training data is
  probably out of date.
