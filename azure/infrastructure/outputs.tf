output "environment_name" {
  value = module.toscacloud.environment_name
}

output "subscription_id" {
  value = module.toscacloud.subscription_id
}

output "tenant_id" {
  value = module.toscacloud.tenant_id
}

output "resource_group_services_name" {
  value = module.toscacloud.resource_group_services_name
}

output "resource_group_clients_name" {
  value = module.toscacloud.resource_group_clients_name
}

# network
output "virtual_network_name" {
  value = module.toscacloud.virtual_network_name
}

output "virtual_network_address_space" {
  value = module.toscacloud.virtual_network_address_space
}

output "subnet_services_name" {
  value = module.toscacloud.subnet_services_name
}

output "subnet_services_address_prefix" {
  value = module.toscacloud.subnet_services_address_prefix
}

output "subnet_services_id" {
  value = module.toscacloud.subnet_services_id
}

output "subnet_clients_name" {
  value = module.toscacloud.subnet_clients_name
}

output "subnet_clients_address_prefix" {
  value = module.toscacloud.subnet_clients_address_prefix
}

output "subnet_clients_id" {
  value = module.toscacloud.subnet_clients_id
}

# storage account
output "storage_account_id" {
  value = module.toscacloud.storage_account_id
}

output "storage_account_name" {
  value = module.toscacloud.storage_account_name
}

# db
output "sql_server_name" {
  value = module.toscacloud.sql_server_name
}

output "sql_server_id" {
  value = module.toscacloud.sql_server_id
}

output "sql_server_fully_qualified_domain_name" {
  value = module.toscacloud.sql_server_fully_qualified_domain_name
}

output "toscadb_name" {
  value = module.toscacloud.toscadb_name
}

output "toscadb_id" {
  value = module.toscacloud.toscadb_id
}

output "toscadb_connection_string" {
  value = module.toscacloud.toscadb_connection_string
}

output "authdb_name" {
  value = module.toscacloud.authdb_name
}

output "authdb_id" {
  value = module.toscacloud.authdb_id
}

output "authdb_connection_string" {
  value = module.toscacloud.authdb_connection_string
}

# image gallery
output "image_gallery_name" {
  value = module.toscacloud.image_gallery_name
}
