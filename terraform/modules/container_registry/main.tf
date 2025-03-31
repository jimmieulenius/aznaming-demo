resource "azurerm_container_registry" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = false
  public_network_access_enabled = false

  lifecycle {
    ignore_changes = [
      tags # Stops Terraform from overwriting tags
    ]
  }
}