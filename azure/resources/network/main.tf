data "azurerm_resource_group" "fess" {
  name = var.azure.resource_group_name
}

####################################################
# VNet
####################################################
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.app_name}-${var.env_name}"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.fess.location
  resource_group_name = data.azurerm_resource_group.fess.name
}

####################################################
# Subnet
####################################################
resource "azurerm_subnet" "fess" {
  name                 = "subnet-fess"
  resource_group_name  = data.azurerm_resource_group.fess.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

####################################################
# Network Security Group
####################################################
resource "azurerm_network_security_group" "public_nsg" {
  name                = "${var.app_name}-${var.env_name}-public-nsg"
  location            = data.azurerm_resource_group.fess.location
  resource_group_name = data.azurerm_resource_group.fess.name
}

resource "azurerm_subnet_network_security_group_association" "public_nsg" {
  subnet_id                 = azurerm_subnet.fess.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.public_nsg.name
  resource_group_name         = data.azurerm_resource_group.fess.name
}

resource "azurerm_network_security_rule" "allow_http_internal" {
  name                        = "allow-http-internal"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["8080", "8443"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.public_nsg.name
  resource_group_name         = data.azurerm_resource_group.fess.name
}

resource "azurerm_network_security_rule" "allow_http_public" {
  name                        = "allow-http-public"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.public_nsg.name
  resource_group_name         = data.azurerm_resource_group.fess.name
}

resource "azurerm_network_security_rule" "allow_es_transport" {
  name                        = "allow-es-transport"
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["9300"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.public_nsg.name
  resource_group_name         = data.azurerm_resource_group.fess.name
}

####################################################
# Azure Bastion
####################################################
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_resource_group.fess.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.255.0/24"]
}

resource "azurerm_public_ip" "bastion_fess" {
  name                = "${var.app_name}-${var.env_name}-bastion-pip"
  location            = data.azurerm_resource_group.fess.location
  resource_group_name = data.azurerm_resource_group.fess.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "fess" {
  name                = "${var.app_name}-${var.env_name}-bastion"
  location            = data.azurerm_resource_group.fess.location
  resource_group_name = data.azurerm_resource_group.fess.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_fess.id
  }
}
