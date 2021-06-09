data "azurerm_shared_image_version" "image_version" {
  name                = var.image_version
  image_name          = var.installation_type
  gallery_name        = var.shared_image_gallery_name
  resource_group_name = var.services_resource_group_name
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.vm_prefix}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = "${var.vm_prefix}-vm"
  tags = {
    Environment = var.environment_name
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
  tags = {
    Environment = var.environment_name
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "${var.vm_prefix}-vm"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = var.size
  source_image_id       = data.azurerm_shared_image_version.image_version.id
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  boot_diagnostics {}
  provision_vm_agent       = true
  enable_automatic_updates = var.enable_automatic_updates


  os_disk {
    name                 = "${var.vm_prefix}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  tags = {
    Environment = var.environment_name
  }
}


resource "azurerm_virtual_machine_extension" "postdeploy" {
  name                 = "${azurerm_windows_virtual_machine.vm.name}-postdeploy"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
  {
    "commandToExecute": "pwsh -ExecutionPolicy Unrestricted -NoProfile -File ${var.postdeploy_script_path} -ServerUri '${var.toscaserver_uri}' -DatabaseUri '${var.database_fqdn}'"
  }
  SETTINGS
}
