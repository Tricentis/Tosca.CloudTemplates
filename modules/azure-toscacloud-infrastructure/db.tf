resource "azurerm_mssql_server" "sql_server" {
  name                          = var.sql_server_name
  resource_group_name           = azurerm_resource_group.rg_services.name
  location                      = azurerm_resource_group.rg_services.location
  version                       = "12.0"
  minimum_tls_version           = "1.2"
  administrator_login           = var.sql_server_admin_login
  administrator_login_password  = var.sql_server_admin_password
  public_network_access_enabled = var.sql_server_allow_network_access

  tags = {
    Environment = var.environment_name
  }
}

resource "azurerm_mssql_virtual_network_rule" "sql_network_rule_services" {
  name                                 = "servicesSubnet"
  server_id                            = azurerm_mssql_server.sql_server.id
  subnet_id                            = azurerm_subnet.subnet_services.id
  ignore_missing_vnet_service_endpoint = false
}

resource "azurerm_mssql_virtual_network_rule" "sql_network_rule_clients" {
  name                                 = "clientsSubnet"
  server_id                            = azurerm_mssql_server.sql_server.id
  subnet_id                            = azurerm_subnet.subnet_clients.id
  ignore_missing_vnet_service_endpoint = false
}

resource "azurerm_mssql_database" "toscadb" {
  name                        = var.tosca_database_name
  server_id                   = azurerm_mssql_server.sql_server.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  license_type                = "LicenseIncluded"
  max_size_gb                 = var.sql_max_size
  min_capacity                = 0.5
  sku_name                    = "GP_S_Gen5_2"
  zone_redundant              = var.sql_zone_redundant
  auto_pause_delay_in_minutes = var.sql_auto_pause_delay

  tags = {
    Environment = var.environment_name
  }
}

resource "azurerm_mssql_database" "authdb" {
  name                        = var.auth_database_name
  server_id                   = azurerm_mssql_server.sql_server.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  license_type                = "LicenseIncluded"
  max_size_gb                 = var.sql_max_size
  min_capacity                = 0.5
  sku_name                    = "GP_S_Gen5_2"
  zone_redundant              = var.sql_zone_redundant
  auto_pause_delay_in_minutes = var.sql_auto_pause_delay

  tags = {
    Environment = var.environment_name
  }
}

resource "azurerm_private_endpoint" "sql_ep" {
  name                = var.sql_private_endpoint
  location            = azurerm_resource_group.rg_services.location
  resource_group_name = azurerm_resource_group.rg_services.name
  subnet_id           = azurerm_subnet.subnet_services.id

  private_service_connection {
    name                           = "toscacloud-link"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
}

resource "azurerm_private_dns_a_record" "sql_dns_record" {
  name                = var.sql_server_name
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = azurerm_resource_group.rg_services.name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.sql_ep.private_service_connection[0].private_ip_address]
}