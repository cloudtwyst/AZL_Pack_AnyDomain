terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.50"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

module "epac_sps" {
  source                   = "../../"
  prefix                   = "contoso"
  root_management_group_id = "/providers/Microsoft.Management/managementGroups/contoso-root"
  github_org               = "my-org"
  github_repo              = "azure-landing-zone"
}
