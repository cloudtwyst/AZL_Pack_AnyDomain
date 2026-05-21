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

resource "azurerm_resource_group" "monitoring" {
  name     = "contoso-rg-monitoring"
  location = "uksouth"
  tags = {
    environment = "shared"
    managed_by  = "terraform"
  }
}

module "monitoring" {
  source              = "../../"
  prefix              = "contoso"
  location            = azurerm_resource_group.monitoring.location
  resource_group_name = azurerm_resource_group.monitoring.name

  log_analytics_topology         = "global"
  log_retention_days             = 180
  event_hub_enabled              = true
  event_hub_max_throughput_units = 20

  tags = {
    environment = "shared"
    cost_center = "platform"
    managed_by  = "terraform"
  }
}

output "workspace_id" {
  value = module.monitoring.log_analytics_workspace_id
}

output "event_hub_id" {
  value = module.monitoring.event_hub_id
}
