locals {
  # Build a flat map of all management groups that were created.
  _caf_ids = var.layout == "caf" ? {
    platform      = azurerm_management_group.platform[0].id
    landingzones  = azurerm_management_group.landingzones[0].id
    corp          = azurerm_management_group.corp[0].id
    online        = azurerm_management_group.online[0].id
    sandbox       = azurerm_management_group.sandbox[0].id
    decommissioned = azurerm_management_group.decommissioned[0].id
  } : {}

  management_group_ids = merge(
    { root = azurerm_management_group.root.id },
    local._caf_ids,
  )

  epac_environments = var.layout == "caf" ? {
    epac-dev    = azurerm_management_group.sandbox[0].id
    epac-nonprod = azurerm_management_group.corp[0].id
    epac-prod   = azurerm_management_group.root.id
  } : {}
}

output "management_group_ids" {
  description = "Map of management group key to Azure resource ID for every group created."
  value       = local.management_group_ids
}

output "root_management_group_id" {
  description = "Resource ID of the root management group created by this module."
  value       = azurerm_management_group.root.id
}

output "epac_environments" {
  description = "EPAC environment map suitable for use in epac-environments.json. Populated only for the 'caf' layout; empty map for flat/custom."
  value       = local.epac_environments
}
