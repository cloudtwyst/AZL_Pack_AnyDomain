# private-dns-zones

Creates Azure Private DNS zones for common PaaS services and optionally links them to one or more virtual networks.

## Default zones

When `zones = []` (the default), the following zones are created:

- `privatelink.blob.core.windows.net`
- `privatelink.file.core.windows.net`
- `privatelink.queue.core.windows.net`
- `privatelink.table.core.windows.net`
- `privatelink.vaultcore.azure.net`
- `privatelink.database.windows.net`
- `privatelink.azurewebsites.net`
- `privatelink.servicebus.windows.net`
- `privatelink.azurecr.io`
- `privatelink.azure-automation.net`
- `privatelink.monitor.azure.com`

Override by setting `zones` to a custom list.

## VNet links

Set `vnet_links` to link every zone to one or more VNets. A link resource is created for **every combination** of zone × VNet link entry. Enabling `auto_registration` on a link allows Azure to automatically register/deregister DNS records for VMs in that VNet — only supported on one link per zone.

## Usage

```hcl
module "private_dns" {
  source              = "../terraform-modules/private-dns-zones"
  resource_group_name = azurerm_resource_group.connectivity.name
  vnet_links = {
    hub = {
      vnet_id           = azurerm_virtual_network.hub.id
      auto_registration = false
    }
  }
  tags = { environment = "shared" }
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `resource_group_name` | string | yes | — | Resource group for DNS zones |
| `zones` | list(string) | no | `[]` (use defaults) | Custom zone list |
| `vnet_links` | map(object) | no | `{}` | VNet links per zone |
| `tags` | map(string) | no | `{}` | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `zone_ids` | Map of zone name → resource ID |
| `zone_names` | List of zone names created |
