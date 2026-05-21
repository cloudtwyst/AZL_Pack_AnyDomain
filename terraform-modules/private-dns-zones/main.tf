locals {
  default_zones = [
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.queue.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.database.windows.net",
    "privatelink.azurewebsites.net",
    "privatelink.servicebus.windows.net",
    "privatelink.azurecr.io",
    "privatelink.azure-automation.net",
    "privatelink.monitor.azure.com",
  ]
  zones_to_create = length(var.zones) > 0 ? var.zones : local.default_zones
}

resource "azurerm_private_dns_zone" "this" {
  for_each = toset(local.zones_to_create)

  name                = each.key
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = {
    for pair in setproduct(keys(azurerm_private_dns_zone.this), keys(var.vnet_links)) :
    "${pair[0]}_${pair[1]}" => { zone = pair[0], link = pair[1] }
  }

  name                  = replace("${each.value.zone}-${each.value.link}", ".", "-")
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.value.zone].name
  virtual_network_id    = var.vnet_links[each.value.link].vnet_id
  registration_enabled  = var.vnet_links[each.value.link].auto_registration
  tags                  = var.tags
}
