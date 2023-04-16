locals {
  env_vars = read_terragrunt_config("${path_relative_from_include()}/env/${get_env("ENV")}.hcl")
}

inputs = {
  env_name   = get_env("ENV")
  app_name   = local.env_vars.locals.app_name
  aws        = local.env_vars.locals.aws
  vpc        = local.env_vars.locals.vpc
  opensearch = local.env_vars.locals.opensearch
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tg_gen.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = local.env_vars.locals.remote_state.bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.env_vars.locals.aws.region
    profile        = local.env_vars.locals.aws.profile
    encrypt        = true
    dynamodb_table = local.env_vars.locals.remote_state.dynamodb_table
  }
}

generate "provider" {
  path      = "provider.tg_gen.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.63.0"
    }
  }
}

provider "aws" {
  region  = "${local.env_vars.locals.aws.region}"
  profile = "${local.env_vars.locals.aws.profile}"
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

variable "aws" {
  type = object({
    profile = string
    region  = string
    azs     = list(string)
  })
}

variable "vpc" {
  type = object({
    name = string
    cidr = string
  })
}

variable "opensearch" {
  type = object({
    engine_version   = string
    instance_type    = string
    instance_count   = number
    volume_size      = number
    master_user_name = string
  })
}
EOF
}
