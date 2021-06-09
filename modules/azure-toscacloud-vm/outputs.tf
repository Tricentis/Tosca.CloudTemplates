output "id" {
  value = azurerm_windows_virtual_machine.vm.id
}

output "name" {
  value = azurerm_windows_virtual_machine.vm.name
}

output "resource_group_name" {
  value = azurerm_windows_virtual_machine.vm.resource_group_name
}

output "size" {
  value = azurerm_windows_virtual_machine.vm.size
}

output "private_ip_address" {
  value = azurerm_windows_virtual_machine.vm.private_ip_address
}

output "public_ip_address" {
  value = azurerm_windows_virtual_machine.vm.public_ip_address
}

output "public_fqdn" {
  value = azurerm_public_ip.public_ip.fqdn
}
