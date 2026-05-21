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
  github_environments      = ["epac-dev", "epac-nonprod", "epac-prod"]
}

output "github_actions_build_vars" {
  description = "Variables to configure in GitHub Actions for the build job."
  value = {
    AZURE_CLIENT_ID = module.epac_sps.epac_build_client_id
    AZURE_TENANT_ID = module.epac_sps.tenant_id
  }
}

output "github_actions_deploy_vars" {
  description = "Variables to configure in GitHub Actions for the deploy job."
  value = {
    AZURE_CLIENT_ID = module.epac_sps.epac_deploy_client_id
    AZURE_TENANT_ID = module.epac_sps.tenant_id
  }
}
