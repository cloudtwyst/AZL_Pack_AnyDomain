output "resource_group_name" {
  description = "Name of the resource group containing the tfstate storage account."
  value       = azurerm_resource_group.this.name
}

output "storage_account_name" {
  description = "Name of the storage account. Use this in the Terraform backend block."
  value       = azurerm_storage_account.this.name
}

output "container_name" {
  description = "Name of the blob container for Terraform state files."
  value       = azurerm_storage_container.tfstate.name
}

output "storage_account_id" {
  description = "Resource ID of the storage account."
  value       = azurerm_storage_account.this.id
}
