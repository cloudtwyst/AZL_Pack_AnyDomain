terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# In practice, the monitoring-backbone module is called first and its outputs
# are passed here. This example shows the wiring explicitly.
resource "azurerm_resource_group" "monitoring" {
  name     = "contoso-rg-monitoring"
  location = "uksouth"
  tags = {
    environment = "shared"
    managed_by  = "terraform"
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "contoso-law"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

module "sentinel" {
  source                       = "../../"
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.this.id
  log_analytics_workspace_name = azurerm_log_analytics_workspace.this.name
  resource_group_name          = azurerm_resource_group.monitoring.name
  location                     = azurerm_resource_group.monitoring.location
  tags = {
    environment = "shared"
    managed_by  = "terraform"
  }
}

output "sentinel_workspace_id" {
  value = module.sentinel.sentinel_workspace_id
}
