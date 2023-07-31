data "azurerm_resource_group" "fess" {
  name = var.azure.resource_group_name
}

####################################################
# NIC
####################################################
resource "azurerm_network_interface" "fess" {
  name                = "${var.env_name}-${var.app_name}-nic"
  location            = data.azurerm_resource_group.fess.location
  resource_group_name = data.azurerm_resource_group.fess.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_fess_id
    private_ip_address_allocation = "Dynamic"
  }
}

####################################################
# VM
####################################################
resource "random_password" "vm" {
  length      = 10
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
}

resource "azurerm_windows_virtual_machine" "fess" {
  count                 = var.fess.vm_count
  name                  = "${var.env_name}-${var.app_name}-node-${count.index}"
  resource_group_name   = data.azurerm_resource_group.fess.name
  location              = data.azurerm_resource_group.fess.location
  size                  = var.fess.vm_size
  admin_username        = "fess"
  admin_password        = random_password.vm.result
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

####################################################
# Load Balancer
####################################################
resource "azurerm_public_ip" "fess" {
  name                = "${var.env_name}-${var.app_name}-ip"
  resource_group_name = data.azurerm_resource_group.fess.name
  location            = data.azurerm_resource_group.fess.location
  allocation_method   = "Static"

  tags = {
    environment = var.env_name
  }
}

resource "azurerm_lb" "fess" {
  name                = "${var.env_name}-${var.app_name}-lb"
  location            = data.azurerm_resource_group.fess.location
  resource_group_name = data.azurerm_resource_group.fess.name

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.fess.id
  }
}

resource "azurerm_lb_backend_address_pool" "fess" {
  loadbalancer_id     = azurerm_lb.fess.id
  name                = "backend"
}

resource "azurerm_network_interface_backend_address_pool_association" "fess" {
  network_interface_id    = azurerm_network_interface.fess.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.fess.id

}

resource "azurerm_lb_probe" "fess" {
  name            = "${var.env_name}-${var.app_name}-probe"
  protocol        = "Http"
  request_path    = "/"
  port            = 8080
  loadbalancer_id = azurerm_lb.fess.id
}

resource "azurerm_lb_rule" "fess" {
  loadbalancer_id                = azurerm_lb.fess.id
  name                           = "rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8080
  frontend_ip_configuration_name = azurerm_lb.fess.frontend_ip_configuration[0].name
  backend_address_pool_ids        = [ azurerm_lb_backend_address_pool.fess.id ]
}