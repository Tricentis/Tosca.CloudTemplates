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
  partner_id = "f986e2c1-1611-44e8-9a38-c48610f2a883"
}
