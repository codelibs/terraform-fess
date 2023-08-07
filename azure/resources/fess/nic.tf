####################################################
# NIC for Fess VM
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
