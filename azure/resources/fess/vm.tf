####################################################
# Availability Set
####################################################

resource "azurerm_availability_set" "fess" {
  name                         = "fessavailabilityset"
  resource_group_name          = data.azurerm_resource_group.fess.name
  location                     = data.azurerm_resource_group.fess.location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
}

####################################################
# VM for Fess
####################################################

locals {
  count         = var.fess.vm_count
  es_node_names = [for i in range(local.count) : "es-${i + 1}"]
  setup_script  = file("${path.module}/src/setup-fess.sh")
}

data "template_file" "setup_fess" {
  count    = var.fess.vm_count
  template = file("${path.module}/src/setup-header.tpl.sh")

  vars = {
    docker_fess_version          = "${var.fess.docker_fess_version}"
    node_name                    = "${local.es_node_names[count.index]}"
    discovery_seed_hosts         = "${join(",", azurerm_network_interface.fess[*].private_ip_address)}"
    network_publish_host         = "${azurerm_network_interface.fess[count.index].private_ip_address}"
    cluster_initial_master_nodes = "${join(",", local.es_node_names)}"
  }
}

resource "azurerm_virtual_machine" "fess" {
  count                 = var.fess.vm_count
  name                  = "${var.env_name}-${var.app_name}-node-${count.index}"
  resource_group_name   = data.azurerm_resource_group.fess.name
  location              = data.azurerm_resource_group.fess.location
  network_interface_ids = [azurerm_network_interface.fess[count.index].id]
  vm_size               = var.fess.vm_size
  availability_set_id   = azurerm_availability_set.fess.id

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.env_name}-${var.app_name}-node-${count.index}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "${var.env_name}-${var.app_name}-node-${count.index}-datadisk"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    disk_size_gb      = var.fess.data_disk_size_gb
    lun               = 0
  }

  os_profile {
    computer_name  = "${var.env_name}-${var.app_name}-node-${count.index}"
    admin_username = "fessadmin"
    admin_password = azurerm_key_vault_secret.fess_vm_password.value
    custom_data    = base64encode("${data.template_file.setup_fess[count.index].rendered}${local.setup_script}")
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
