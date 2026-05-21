resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

resource "azurerm_eventhub_namespace" "this" {
  count = var.event_hub_enabled ? 1 : 0

  name                     = "${var.prefix}-ehns"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku                      = "Standard"
  auto_inflate_enabled     = true
  maximum_throughput_units = var.event_hub_max_throughput_units
  tags                     = var.tags
}

resource "azurerm_eventhub" "diagnostics" {
  count = var.event_hub_enabled ? 1 : 0

  name                = "diagnostics"
  namespace_name      = azurerm_eventhub_namespace.this[0].name
  resource_group_name = var.resource_group_name
  partition_count     = 4
  message_retention   = 7
}

resource "azurerm_eventhub_authorization_rule" "siem" {
  count = var.event_hub_enabled ? 1 : 0

  name                = "siem-reader"
  namespace_name      = azurerm_eventhub_namespace.this[0].name
  eventhub_name       = azurerm_eventhub.diagnostics[0].name
  resource_group_name = var.resource_group_name
  listen              = true
  send                = false
  manage              = false
}
