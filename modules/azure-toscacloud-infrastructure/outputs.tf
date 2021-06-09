output "environment_name" {
  value = var.environment_name
}

output "subscription_id" {
  value = var.subscriptionId
}

output "tenant_id" {
  value = var.tenantId
}

output "resource_group_services_name" {
  value = var.resource_group_services_name
}

output "resource_group_clients_name" {
  value = var.resource_group_clients_name
}

# network
output "virtual_network_name" {
  value = azurerm_virtual_network.vnet.name
}

output "virtual_network_address_space" {
  value = azurerm_virtual_network.vnet.address_space
}

output "subnet_services_name" {
  value = azurerm_subnet.subnet_services.name
}

output "subnet_services_address_prefix" {
  value = azurerm_subnet.subnet_services.address_prefix
}

output "subnet_services_id" {
  value = azurerm_subnet.subnet_services.id
}

output "subnet_clients_name" {
  value = azurerm_subnet.subnet_clients.name
}

output "subnet_clients_address_prefix" {
  value = azurerm_subnet.subnet_clients.address_prefix
}

output "subnet_clients_id" {
  value = azurerm_subnet.subnet_clients.id
}

# storage account
output "storage_account_id" {
  value = azurerm_storage_account.storage_account.name
}

output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}

output "storage_account_connection_string" {
  sensitive = true
  value     = azurerm_storage_account.storage_account.primary_connection_string
}

# db
output "sql_server_name" {
  value = azurerm_mssql_server.sql_server.name
}

output "sql_server_id" {
  value = azurerm_mssql_server.sql_server.id
}

output "sql_server_fully_qualified_domain_name" {
  value = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}

output "toscadb_name" {
  value = azurerm_mssql_database.toscadb.name
}

output "toscadb_id" {
  value = azurerm_mssql_database.toscadb.id
}

output "toscadb_connection_string" {
  value = "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.toscadb.name};Persist Security Info=False;User ID=<administrator_login>;Password=<administrator_password>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

output "authdb_name" {
  value = azurerm_mssql_database.authdb.name
}

output "authdb_id" {
  value = azurerm_mssql_database.authdb.id
}

output "authdb_connection_string" {
  value = "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.authdb.name};Persist Security Info=False;User ID=<administrator_login>;Password=<administrator_password>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

# image gallery
output "image_gallery_name" {
  value = azurerm_shared_image_gallery.gallery.name
}
