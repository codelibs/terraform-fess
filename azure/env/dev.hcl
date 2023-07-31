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
    vm_count = 1
    vm_size = "Standard_B2s"
  }
}