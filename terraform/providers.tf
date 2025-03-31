terraform {
  required_version = ">= 1.9.4"

  required_providers {
    azurerm = {
      version = "~>4.0.1"
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}