output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "log_analytics_primary_shared_key" {
  description = "Primary shared key for the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "event_hub_namespace_id" {
  description = "Resource ID of the Event Hub namespace. Empty string when event_hub_enabled = false."
  value       = var.event_hub_enabled ? azurerm_eventhub_namespace.this[0].id : ""
}

output "event_hub_id" {
  description = "Resource ID of the diagnostics Event Hub. Empty string when event_hub_enabled = false."
  value       = var.event_hub_enabled ? azurerm_eventhub.diagnostics[0].id : ""
}

output "event_hub_auth_rule_id" {
  description = "Resource ID of the siem-reader authorization rule. Empty string when event_hub_enabled = false."
  value       = var.event_hub_enabled ? azurerm_eventhub_authorization_rule.siem[0].id : ""
}

output "event_hub_auth_rule_primary_connection_string" {
  description = "Primary connection string for the siem-reader authorization rule. Empty string when event_hub_enabled = false."
  value       = var.event_hub_enabled ? azurerm_eventhub_authorization_rule.siem[0].primary_connection_string : ""
  sensitive   = true
}
