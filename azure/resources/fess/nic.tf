####################################################
# NIC for Fess VM
####################################################

/*
resource "azurerm_public_ip" "fess_public_ip" {
  count               = var.fess.vm_count
  name                = "fess_public_ip-${count.index}"
  location            = data.azurerm_resource_group.fess.location
  resource_group_name = data.azurerm_resource_group.fess.name
  allocation_method   = "Dynamic"
}
*/

resource "azurerm_network_interface" "fess" {
  count               = var.fess.vm_count
  name                = "${var.env_name}-${var.app_name}-nic-${count.index}"
  location            = data.azurerm_resource_group.fess.location
  resource_group_name = data.azurerm_resource_group.fess.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_fess_id
    private_ip_address_allocation = "Dynamic"
    //public_ip_address_id          = azurerm_public_ip.fess_public_ip[count.index].id
  }
}
