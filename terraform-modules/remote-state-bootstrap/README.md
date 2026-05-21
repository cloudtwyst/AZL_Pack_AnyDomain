# remote-state-bootstrap

Creates the Azure Storage Account used as the Terraform remote state backend.

Deploy this module **once per customer** before running any other module. Run it with
local state, then migrate once the account exists.

## Usage

```hcl
module "tfstate" {
  source   = "../../"
  prefix   = "contoso"
  location = "westeurope"
  tags     = { Environment = "management" }
}
```

After first apply configure your backend:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "contoso-rg-tfstate"
    storage_account_name = "contosotfstate"
    container_name       = "tfstate"
    key                  = "foundation.tfstate"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| azurerm | ~> 4.0 |

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| prefix | string | yes | Customer shortCode (max 8 chars) |
| location | string | yes | Azure region |
| tags | map(string) | no | Tags applied to all resources |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_name | Resource group name |
| storage_account_name | Storage account name |
| container_name | Blob container name |
| storage_account_id | Storage account resource ID |
