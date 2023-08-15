locals {
  app_name = "fess"
  remote_state = {
    container_name = "terraform-fess"
  }
  azure = {
    resource_group_name = "tf-fess-test"
    storage_account_name = "fess"
  }
  fess = {
    docker_fess_version = "v14.10.0"
    vm_count = 2
    vm_size = "Standard_B2ms"
    data_disk_size_gb = 50
  }
}