locals {
  env_vars = read_terragrunt_config("${path_relative_from_include()}/env/${get_env("ENV")}.hcl")
}

inputs = {
  env_name   = get_env("ENV")
  app_name   = local.env_vars.locals.app_name
  azure = local.env_vars.locals.azure
  fess = local.env_vars.locals.fess
}

remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tg_gen.tf"
    if_exists = "overwrite"
  }
  config = {
    resource_group_name   = local.env_vars.locals.azure.resource_group_name
    storage_account_name  = local.env_vars.locals.azure.storage_account_name
    container_name        = local.env_vars.locals.remote_state.container_name
    key                   = "tfstate/${get_env("ENV")}/${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "provider" {
  path      = "provider.tg_gen.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.66.0"
    }
  }
}

provider "azurerm" {
  features {}
}
EOF
}

generate "config" {
  path      = "config.tg_gen.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "1.4.5"
}

variable "env_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "azure" {
  type = object({
    resource_group_name = string
    storage_account_name = string
  })
}

variable "fess" {
  type = object({
    docker_fess_version = string
    vm_count = number
    vm_size  = string
    data_disk_size_gb = number
  })
}

EOF
}
