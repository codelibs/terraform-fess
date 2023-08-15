locals {
  current_time = formatdate("YYYYMMDDhhmmss", timestamp())
}

####################################################
# Key Vault
####################################################
resource "azurerm_key_vault" "fess" {
  name                        = "${var.env_name}-${var.app_name}-secrets"
  location                    = data.azurerm_resource_group.fess.location
  resource_group_name         = data.azurerm_resource_group.fess.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.tf_client.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.tf_client.tenant_id
    object_id = data.azurerm_client_config.tf_client.object_id

    key_permissions = [
    ]

    secret_permissions = [
      "Get",
      "Set",
      "List",
      "Delete",
      "Purge",
    ]

    certificate_permissions = [
    ]
  }
}

####################################################
# Secret: VM Password for Fess
####################################################

resource "random_id" "fess_vm_secret_id" {
  byte_length = 8
  keepers = {
    example_value = "${var.env_name}-${var.app_name}"
  }
}

resource "random_password" "fess_vm" {
  length      = 10
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  special     = false
}

resource "azurerm_key_vault_secret" "fess_vm_password" {
  name         = "vm-pass-${random_id.fess_vm_secret_id.hex}"
  value        = random_password.fess_vm.result
  key_vault_id = azurerm_key_vault.fess.id

  depends_on = [
    azurerm_key_vault.fess
  ]
}
