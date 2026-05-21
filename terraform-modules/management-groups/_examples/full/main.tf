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

module "management_groups" {
  source      = "../../"
  root_prefix = "contoso"
  layout      = "caf"

  subscription_ids = {
    platform       = ["00000000-0000-0000-0000-000000000001"]
    landingzones   = []
    corp           = ["00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000003"]
    online         = ["00000000-0000-0000-0000-000000000004"]
    sandbox        = ["00000000-0000-0000-0000-000000000005"]
    decommissioned = []
  }
}

output "management_group_ids" {
  value = module.management_groups.management_group_ids
}

output "epac_environments" {
  description = "Feed this into EPAC global-settings.jsonc."
  value       = module.management_groups.epac_environments
}
