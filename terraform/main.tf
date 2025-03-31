locals {
  resource_names = jsondecode(var.resource_names_json)
}

module "key_vault" {
  source = "./modules/key_vault"
  name = local.resource_names.key_vault.vault
  location = var.location
  resource_group = local.resource_names.resource_group
  tenant_id = var.tenant_id
}

module "container_registry" {
  source = "./modules/container_registry"
  name = local.resource_names.container_registry.registry
  location = var.location
  resource_group = local.resource_names.resource_group
  sku = "Premium"
}