provider "azurerm" {
  features {}
}

module "tfstate" {
  source   = "../../"
  prefix   = "contoso"
  location = "westeurope"
  tags = {
    Environment = "management"
    Owner       = "platform-team"
    CostCenter  = "infra-001"
    ManagedBy   = "terraform"
  }
}

output "storage_account_name" {
  value = module.tfstate.storage_account_name
}
