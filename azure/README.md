# Terraform for Fess on Azure

## Setup on Azure

Prepare the following resources on Azure.

* Resource Group for Fess Resources.
* Strage Account for tfstate.
* Blob Container for tfstate.

## Setup

### Setup Env

Set the 'env' file according to the Azure environment in use.

* container_name
* resource_group_name
* storage_account_name

### Install Terraform and Terragrunt

```
tgenv install
tfenv install
```

### Init

```
ENV=dev terragrunt init -reconfigure --terragrunt-working-dir ./resources/network
ENV=dev terragrunt init -reconfigure --terragrunt-working-dir ./resources/fess
```

## Deploy

### Network
```
ENV=dev terragrunt plan --terragrunt-working-dir ./resources/network
ENV=dev terragrunt apply --terragrunt-working-dir ./resources/network
```

### Fess
```
ENV=dev terragrunt plan --terragrunt-working-dir ./resources/fess
ENV=dev terragrunt apply --terragrunt-working-dir ./resources/fess
```

## Login VM

Log in to the VM using Azure Bastion. User name is 'fess'.

### Verify the VM password.

```
ENV=dev terragrunt output -json --terragrunt-working-dir ./resources/fess
```