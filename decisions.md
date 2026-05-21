# Decisions

Open and closed architecture decisions for this pack. Append entries here whenever
a choice is made; never delete old entries.

Format: `## D{N} — {title}` then Status, Date, Decision, Reason.

---

## D1 — Config schema format

- **Status:** Closed
- **Date:** 2026-05-21
- **Decision:** Use JSON Schema draft-07 (not draft 2020-12).
- **Reason:** PowerShell 7's built-in `Test-Json -Schema` uses Newtonsoft.Json.Schema, which supports draft-07. Avoids pulling in an external NuGet package for the validator.

## D2 — IaC language for foundation modules

- **Status:** Closed
- **Date:** 2026-05-21
- **Decision:** Terraform (azurerm ~> 4.0, azuread ~> 2.50, pinned to >= 1.6.0).
- **Reason:** SOLUTION-PACK.md default; Terraform's provider coverage for azurerm/azuread is more complete than Bicep for the OIDC federation and RBAC resources needed by the service-principals module.

## D3 — Template engine for the CLI

- **Status:** Closed
- **Date:** 2026-05-21
- **Decision:** `{{PLACEHOLDER}}` string replacement via PowerShell `String.Replace()` for static tokens; PowerShell script logic for loops and conditionals (e.g. terraform/main.tf generation).
- **Reason:** Mustache requires an external module. The current template surface is small and all loops (e.g. multi-region topologies, multiple frameworks) are handled in dedicated PowerShell functions (Build-TerraformMain, Build-EpacGlobalSettings) rather than in template files. Revisit for W5 if workflow templates need loops.

## D4 — YAML parser dependency

- **Status:** Closed
- **Date:** 2026-05-21
- **Decision:** `powershell-yaml` module (Install-Module powershell-yaml).
- **Reason:** Standard community module; widely used in EPAC adjacent tooling. No binary dependency. Checked at runtime with a clear error message if missing.
