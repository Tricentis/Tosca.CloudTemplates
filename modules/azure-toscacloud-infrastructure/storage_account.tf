resource "azurerm_storage_account" "storage_account" {
  name                      = var.storage_account_name
  resource_group_name       = azurerm_resource_group.rg_services.name
  location                  = azurerm_resource_group.rg_services.location
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  access_tier               = "Hot"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
  allow_blob_public_access  = true

  network_rules {
    default_action             = var.storage_account_allow_network_access ? "Allow" : "Deny"
    ip_rules                   = []
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.subnet_services.id, azurerm_subnet.subnet_clients.id]
  }

  tags = {
    Environment = var.environment_name
  }
}

resource "azurerm_storage_container" "setup" {
  name                  = "setup"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "deployment" {
  name                  = "deployment"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}