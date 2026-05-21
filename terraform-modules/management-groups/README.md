# management-groups

Creates a CAF-aligned Azure management group hierarchy. Three layouts are supported:

| Layout | Groups created |
|--------|---------------|
| `caf` | root → platform, landingzones (corp, online), sandbox, decommissioned |
| `flat` | root only |
| `custom` | root only — extend the tree manually |

## Usage

```hcl
module "management_groups" {
  source       = "../terraform-modules/management-groups"
  root_prefix  = "contoso"
  layout       = "caf"
  subscription_ids = {
    platform       = ["00000000-0000-0000-0000-000000000001"]
    corp           = ["00000000-0000-0000-0000-000000000002"]
    sandbox        = ["00000000-0000-0000-0000-000000000003"]
    decommissioned = []
  }
}
```

## EPAC integration

The `epac_environments` output maps EPAC environment names to management group IDs:

```json
{
  "epac-dev":    "<sandbox-mg-id>",
  "epac-nonprod": "<corp-mg-id>",
  "epac-prod":   "<root-mg-id>"
}
```

Pass these values to your EPAC `global-settings.jsonc` via a Terraform template or pipeline variable.

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `root_prefix` | string | yes | — | Prefix for all management group names |
| `layout` | string | no | `"caf"` | Hierarchy layout: caf, flat, custom |
| `subscription_ids` | map(list(string)) | no | `{}` | Subscriptions to associate per MG key |

## Outputs

| Name | Description |
|------|-------------|
| `management_group_ids` | Map of MG key → resource ID |
| `root_management_group_id` | Root MG resource ID |
| `epac_environments` | EPAC environment map (CAF layout only) |
