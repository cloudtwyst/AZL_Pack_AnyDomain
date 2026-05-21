# monitoring-backbone

Deploys a Log Analytics workspace and (optionally) an Event Hub namespace for DINE-driven centralized monitoring.

## Topology

The `log_analytics_topology` variable is a documentation label that reflects your intended design. The module always creates exactly **one** workspace per call. For multi-region topologies, call the module once per region:

```hcl
module "monitoring_uksouth" {
  source                 = "../terraform-modules/monitoring-backbone"
  prefix                 = "contoso-uksouth"
  location               = "uksouth"
  resource_group_name    = "contoso-rg-monitoring-uksouth"
  log_analytics_topology = "per-region"
}

module "monitoring_westeurope" {
  source                 = "../terraform-modules/monitoring-backbone"
  prefix                 = "contoso-westeurope"
  location               = "westeurope"
  resource_group_name    = "contoso-rg-monitoring-westeurope"
  log_analytics_topology = "per-region"
}
```

## Event Hub

When `event_hub_enabled = true`, the module creates:

- An Event Hub namespace (`Standard` SKU, auto-inflate)
- A `diagnostics` Event Hub (4 partitions, 7-day retention)
- A `siem-reader` authorization rule (listen-only) for SIEM integration

## Usage

```hcl
module "monitoring" {
  source              = "../terraform-modules/monitoring-backbone"
  prefix              = "contoso"
  location            = "uksouth"
  resource_group_name = azurerm_resource_group.monitoring.name
  tags                = { environment = "shared" }
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `prefix` | string | yes | — | Resource name prefix |
| `location` | string | yes | — | Azure region |
| `resource_group_name` | string | yes | — | Pre-existing resource group |
| `log_analytics_topology` | string | no | `"global"` | Topology label (global/per-region/per-continent) |
| `additional_locations` | list(string) | no | `[]` | Informational list of extra regions |
| `event_hub_enabled` | bool | no | `true` | Create Event Hub resources |
| `event_hub_max_throughput_units` | number | no | `10` | Max auto-inflate throughput units |
| `log_retention_days` | number | no | `90` | Workspace retention (30–730 days) |
| `tags` | map(string) | no | `{}` | Resource tags |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `log_analytics_workspace_id` | no | Workspace resource ID |
| `log_analytics_workspace_name` | no | Workspace name |
| `log_analytics_primary_shared_key` | yes | Workspace shared key |
| `event_hub_namespace_id` | no | Namespace resource ID |
| `event_hub_id` | no | Diagnostics hub resource ID |
| `event_hub_auth_rule_id` | no | SIEM auth rule resource ID |
| `event_hub_auth_rule_primary_connection_string` | yes | SIEM connection string |
