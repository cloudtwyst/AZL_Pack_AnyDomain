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

module "sentinel" {
  source                       = "../../"
  log_analytics_workspace_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/contoso-rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/contoso-law"
  log_analytics_workspace_name = "contoso-law"
  resource_group_name          = "contoso-rg-monitoring"
  location                     = "uksouth"
}
