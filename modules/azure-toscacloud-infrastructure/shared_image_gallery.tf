resource "azurerm_shared_image_gallery" "gallery" {
  name                = var.image_gallery_name
  resource_group_name = azurerm_resource_group.rg_services.name
  location            = azurerm_resource_group.rg_services.location

  tags = {
    Environment = var.environment_name
  }
}