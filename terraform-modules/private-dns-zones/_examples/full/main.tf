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

resource "azurerm_resource_group" "connectivity" {
  name     = "contoso-rg-connectivity"
  location = "uksouth"
  tags = {
    environment = "shared"
    managed_by  = "terraform"
  }
}

resource "azurerm_virtual_network" "hub" {
  name                = "contoso-vnet-hub"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  address_space       = ["10.0.0.0/16"]
}

module "private_dns" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.connectivity.name

  # Override with a custom subset of zones.
  zones = [
    "privatelink.blob.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.database.windows.net",
    "privatelink.azurecr.io",
  ]

  vnet_links = {
    hub = {
      vnet_id           = azurerm_virtual_network.hub.id
      auto_registration = false
    }
  }

  tags = {
    environment = "shared"
    cost_center = "platform"
    managed_by  = "terraform"
  }
}

output "zone_ids" {
  value = module.private_dns.zone_ids
}
