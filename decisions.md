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

- **Status:** Open
- **Question:** Terraform or Bicep for `terraform-modules/`?
- **Default:** Terraform (as per SOLUTION-PACK.md). Confirm before W2 starts.

## D3 — Template engine for the CLI

- **Status:** Open
- **Question:** PowerShell `ExpandString` (simple) or pwsh-callable Mustache (loops/conditionals)?
- **Default:** Decide during W4. SOLUTION-PACK.md recommends Mustache for anything with loops.

## D4 — YAML parser dependency

- **Status:** Closed
- **Date:** 2026-05-21
- **Decision:** `powershell-yaml` module (Install-Module powershell-yaml).
- **Reason:** Standard community module; widely used in EPAC adjacent tooling. No binary dependency. Checked at runtime with a clear error message if missing.
