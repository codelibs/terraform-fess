data "azurerm_resource_group" "fess" {
  name = var.azure.resource_group_name
}

data "azurerm_client_config" "tf_client" {}

