/*
output "admin_password" {
  sensitive = true
  value     = azurerm_windows_virtual_machine.fess.*.admin_password
}
*/

output "admin_password_secret_name" {
  value = azurerm_key_vault_secret.fess_vm_password.name
}

output "admin_password" {
  sensitive = true
  value     = azurerm_key_vault_secret.fess_vm_password.value
}
