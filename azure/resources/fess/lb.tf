####################################################
# Load Balancer for Fess
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
  loadbalancer_id = azurerm_lb.fess.id
  name            = "backend"

  depends_on = [
    azurerm_virtual_machine.fess
  ]
}

resource "azurerm_network_interface_backend_address_pool_association" "fess" {
  count                   = var.fess.vm_count
  network_interface_id    = azurerm_network_interface.fess[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.fess.id
}

resource "azurerm_lb_probe" "fess" {
  name            = "${var.env_name}-${var.app_name}-probe"
  protocol        = "Http"
  request_path    = "/"
  port            = 8080
  loadbalancer_id = azurerm_lb.fess.id

  depends_on = [
    azurerm_virtual_machine.fess,
    azurerm_network_interface.fess,
    azurerm_network_interface_backend_address_pool_association.fess
  ]
}

resource "azurerm_lb_rule" "fess" {
  loadbalancer_id                = azurerm_lb.fess.id
  name                           = "rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8080
  frontend_ip_configuration_name = azurerm_lb.fess.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.fess.id]
  load_distribution              = "SourceIPProtocol"
}
