resource "azurerm_management_group" "root" {
  name             = "${var.root_prefix}-root"
  display_name     = "${var.root_prefix} Root"
  subscription_ids = lookup(var.subscription_ids, "root", [])
}

resource "azurerm_management_group" "platform" {
  count = var.layout == "caf" ? 1 : 0

  name                       = "${var.root_prefix}-platform"
  display_name               = "${var.root_prefix} Platform"
  parent_management_group_id = azurerm_management_group.root.id
  subscription_ids           = lookup(var.subscription_ids, "platform", [])
}

resource "azurerm_management_group" "landingzones" {
  count = var.layout == "caf" ? 1 : 0

  name                       = "${var.root_prefix}-landingzones"
  display_name               = "${var.root_prefix} Landing Zones"
  parent_management_group_id = azurerm_management_group.root.id
  subscription_ids           = lookup(var.subscription_ids, "landingzones", [])
}

resource "azurerm_management_group" "corp" {
  count = var.layout == "caf" ? 1 : 0

  name                       = "${var.root_prefix}-corp"
  display_name               = "${var.root_prefix} Corp"
  parent_management_group_id = azurerm_management_group.landingzones[0].id
  subscription_ids           = lookup(var.subscription_ids, "corp", [])
}

resource "azurerm_management_group" "online" {
  count = var.layout == "caf" ? 1 : 0

  name                       = "${var.root_prefix}-online"
  display_name               = "${var.root_prefix} Online"
  parent_management_group_id = azurerm_management_group.landingzones[0].id
  subscription_ids           = lookup(var.subscription_ids, "online", [])
}

resource "azurerm_management_group" "sandbox" {
  count = var.layout == "caf" ? 1 : 0

  name                       = "${var.root_prefix}-sandbox"
  display_name               = "${var.root_prefix} Sandbox"
  parent_management_group_id = azurerm_management_group.root.id
  subscription_ids           = lookup(var.subscription_ids, "sandbox", [])
}

resource "azurerm_management_group" "decommissioned" {
  count = var.layout == "caf" ? 1 : 0

  name                       = "${var.root_prefix}-decommissioned"
  display_name               = "${var.root_prefix} Decommissioned"
  parent_management_group_id = azurerm_management_group.root.id
  subscription_ids           = lookup(var.subscription_ids, "decommissioned", [])
}
