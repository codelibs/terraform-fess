include "root" {
  path = find_in_parent_folders()
}

dependency "network" {
  config_path = "${path_relative_from_include("root")}/resources/network"
}

inputs = {
  subnet_fess_id = dependency.network.outputs.subnet_fess_id
}

dependencies {
  paths = ["${path_relative_from_include("root")}/resources/network"]
}