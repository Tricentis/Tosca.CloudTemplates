module "toscacloud" {
  source = "../../modules/azure-toscacloud-infrastructure"

  subscriptionId                       = var.subscriptionId
  tenantId                             = var.tenantId
  location                             = var.location
  resource_group_services_name         = var.resource_group_services_name
  resource_group_clients_name          = var.resource_group_clients_name
  virtual_network_name                 = var.virtual_network_name
  storage_account_name                 = var.storage_account_name
  image_gallery_name                   = var.image_gallery_name
  sql_server_name                      = var.sql_server_name
  sql_server_admin_login               = var.sql_server_admin_login
  sql_server_admin_password            = var.sql_server_admin_password
  sql_server_allow_network_access      = var.sql_server_allow_network_access
  tosca_database_name                  = var.tosca_database_name
  auth_database_name                   = var.auth_database_name
  sql_private_endpoint                 = var.sql_private_endpoint
  sql_sku                              = var.sql_sku
  sql_max_size                         = var.sql_max_size
  sql_auto_pause_delay                 = var.sql_auto_pause_delay
  sql_zone_redundant                   = var.sql_zone_redundant
  storage_account_allow_network_access = var.storage_account_allow_network_access
}