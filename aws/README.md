# Terraform for Fess on AWS

## Setup

### Install Terraform and Terragrunt

```
tgenv install
tfenv install
```

### Update Enviroment File

You need to modify a value of `remote_state` > `bucket`.

```
  remote_state = {
    bucket         = "dev-fess-1234567890-tfstate"
```

`ENV=dev` uses env/dev.hcl file.

## Deploy

### VPC
```
ENV=dev terragrunt plan --terragrunt-working-dir ./resources/vpc
ENV=dev terragrunt apply --terragrunt-working-dir ./resources/vpc
```

### OpenSearch

```
ENV=dev terragrunt plan --terragrunt-working-dir ./resources/opensearch
ENV=dev terragrunt apply --terragrunt-working-dir ./resources/opensearch
```

### Fess

TBD

## Destroy

```
ENV=dev terragrunt destroy --terragrunt-working-dir ./resources/opensearch
ENV=dev terragrunt destroy --terragrunt-working-dir ./resources/vpc
```
