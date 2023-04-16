include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "${path_relative_from_include("root")}/resources/vpc"
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
}

dependencies {
  paths = ["${path_relative_from_include("root")}/resources/vpc"]
}