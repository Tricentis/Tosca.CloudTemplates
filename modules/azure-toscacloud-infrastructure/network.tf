resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name
  address_space       = ["10.3.0.0/16"]

  tags = {
    Environment = var.environment_name
  }
}

resource "azurerm_subnet" "subnet_services" {
  name                                           = "services"
  resource_group_name                            = azurerm_resource_group.rg_services.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  enforce_private_link_service_network_policies  = false
  enforce_private_link_endpoint_network_policies = true
  address_prefixes                               = ["10.3.1.0/24"]
  service_endpoints                              = ["Microsoft.Sql", "Microsoft.Storage"]
}

resource "azurerm_network_security_group" "nsg_services" {
  name                = "${var.virtual_network_name}-services-nsg"
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name

  tags = {
    Environment = var.environment_name
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_services" {
  subnet_id                 = azurerm_subnet.subnet_services.id
  network_security_group_id = azurerm_network_security_group.nsg_services.id
}

resource "azurerm_subnet" "subnet_clients" {
  name                                           = "clients"
  resource_group_name                            = azurerm_resource_group.rg_services.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  enforce_private_link_service_network_policies  = false
  enforce_private_link_endpoint_network_policies = true
  address_prefixes                               = ["10.3.32.0/19"]
  service_endpoints                              = ["Microsoft.Sql", "Microsoft.Storage"]
}

resource "azurerm_network_security_group" "nsg_clients" {
  name                = "${var.virtual_network_name}-clients-nsg"
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name

  tags = {
    Environment = var.environment_name
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_clients" {
  subnet_id                 = azurerm_subnet.subnet_clients.id
  network_security_group_id = azurerm_network_security_group.nsg_clients.id
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.rg_services.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "network_link" {
  name                  = "privatelink.database.windows.net-${var.virtual_network_name}"
  resource_group_name   = azurerm_resource_group.rg_services.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false

  tags = {
    Environment = var.environment_name
  }
}