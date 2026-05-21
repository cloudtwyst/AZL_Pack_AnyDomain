resource "azurerm_sentinel_log_analytics_workspace_onboarding" "this" {
  workspace_id = var.log_analytics_workspace_id
}
