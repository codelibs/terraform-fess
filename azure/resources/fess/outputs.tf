output "admin_password" {
  sensitive = true
  value     = azurerm_windows_virtual_machine.fess.*.admin_password
}