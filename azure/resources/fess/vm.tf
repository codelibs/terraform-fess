####################################################
# VM for Fess
####################################################

resource "azurerm_virtual_machine" "fess" {
  count                 = var.fess.vm_count
  name                  = "${var.env_name}-${var.app_name}-node3-${count.index}"
  resource_group_name   = data.azurerm_resource_group.fess.name
  location              = data.azurerm_resource_group.fess.location
  network_interface_ids = [azurerm_network_interface.fess.id]
  vm_size               = var.fess.vm_size

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "fessosdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.env_name}-${var.app_name}-node-${count.index}"
    admin_username = "fessadmin"
    admin_password = azurerm_key_vault_secret.fess_vm_password.value
    custom_data = filebase64("${path.module}/src/setup-fess.sh")
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    type = "fess_vm"
  }


  depends_on = [
    azurerm_network_interface.fess,
  ]
}

/*
resource "azurerm_windows_virtual_machine" "fess" {
  count                 = var.fess.vm_count
  name                  = "${var.env_name}-${var.app_name}-node-${count.index}"
  resource_group_name   = data.azurerm_resource_group.fess.name
  location              = data.azurerm_resource_group.fess.location
  size                  = var.fess.vm_size
  admin_username        = "fess"
  admin_password        = local.admin_password
  network_interface_ids = [azurerm_network_interface.fess.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }
}
*/
