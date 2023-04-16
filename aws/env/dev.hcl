locals {
  app_name = "fess"
  remote_state = {
    bucket         = "dev-fess-1234567890-tfstate"
    dynamodb_table = "dev-fess-locktable"
  }
  aws = {
    profile = "default"
    region  = "ap-northeast-1"
    azs     = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  }
  vpc = {
    name = "dev-fess-vpc"
    cidr = "10.0.0.0/16"
  }
  opensearch = {
    engine_version   = "OpenSearch_2.5"
    instance_type    = "t3.medium.search"
    instance_count   = 3
    volume_size      = 10
    master_user_name = "searchadmin"
  }
}