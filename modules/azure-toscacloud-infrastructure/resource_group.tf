resource "azurerm_resource_group" "rg_services" {
  name     = var.resource_group_services_name
  location = var.location
  tags = {
    Environment = var.environment_name
  }
}

resource "azurerm_resource_group" "rg_clients" {
  name     = var.resource_group_clients_name
  location = var.location
  tags = {
    Environment = var.environment_name
  }
}
