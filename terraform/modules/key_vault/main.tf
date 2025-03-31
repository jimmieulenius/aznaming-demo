resource "azurerm_key_vault" "this" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group
  tenant_id                   = var.tenant_id
  purge_protection_enabled    = false
  enabled_for_disk_encryption = false
  sku_name                    = "standard"
  enable_rbac_authorization   = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  lifecycle {
    ignore_changes = [
      tags # Stops Terraform from overwriting tags
    ]
  }
}
