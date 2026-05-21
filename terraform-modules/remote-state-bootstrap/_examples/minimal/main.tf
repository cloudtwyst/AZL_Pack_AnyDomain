provider "azurerm" {
  features {}
}

module "tfstate" {
  source   = "../../"
  prefix   = "fabrikam"
  location = "westeurope"
}

output "backend_config" {
  value = {
    resource_group_name  = module.tfstate.resource_group_name
    storage_account_name = module.tfstate.storage_account_name
    container_name       = module.tfstate.container_name
  }
}
