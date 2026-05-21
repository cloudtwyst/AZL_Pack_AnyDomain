# sentinel

Onboards a Log Analytics workspace to Microsoft Sentinel.

> This module is instantiated only when `monitoring.siem = "sentinel"` in your solution-pack configuration. When using a third-party SIEM (Splunk, QRadar, etc.) via Event Hub, omit this module.

## Usage

```hcl
module "sentinel" {
  source                       = "../terraform-modules/sentinel"
  log_analytics_workspace_id   = module.monitoring.log_analytics_workspace_id
  log_analytics_workspace_name = module.monitoring.log_analytics_workspace_name
  resource_group_name          = azurerm_resource_group.monitoring.name
  location                     = "uksouth"
  tags                         = { environment = "shared" }
}
```

## Pre-requisites

- The target Log Analytics workspace must exist before this module is applied.
- The deploying identity requires `Microsoft.OperationsManagement/solutions/write` on the workspace resource group (granted by the `Log Analytics Contributor` role).

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `log_analytics_workspace_id` | string | yes | Workspace resource ID |
| `log_analytics_workspace_name` | string | yes | Workspace name |
| `resource_group_name` | string | yes | Resource group containing the workspace |
| `location` | string | yes | Azure region |
| `tags` | map(string) | no | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `sentinel_workspace_id` | Resource ID of the Sentinel-onboarded workspace |
