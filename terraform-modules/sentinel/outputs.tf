output "sentinel_workspace_id" {
  description = "Resource ID of the Log Analytics workspace that has been onboarded to Microsoft Sentinel."
  value       = azurerm_sentinel_log_analytics_workspace_onboarding.this.workspace_id
}
