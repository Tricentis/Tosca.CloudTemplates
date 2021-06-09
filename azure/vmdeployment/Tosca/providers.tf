terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.59.0"

    }
  }
}

provider "azurerm" {
  features {}
  partner_id = var.installation_type == "DexAgent" ? "81157b24-3f22-4b29-9481-14b2c2c3ce4b" : "0aea04d9-176e-4d23-afc4-dfc4afd8b03e"
}
