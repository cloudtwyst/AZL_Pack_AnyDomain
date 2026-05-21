resource "azurerm_resource_group" "this" {
  name     = "${var.prefix}-rg-tfstate"
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "this" {
  # Name must be globally unique, 3-24 chars, lowercase alphanumeric only.
  name                     = "${var.prefix}tfstate"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}
