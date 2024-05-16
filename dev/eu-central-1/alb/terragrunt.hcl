# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder. If any environment
# needs to deploy a different module version, it should redefine this block with a different ref to override the
# deployed version.
terraform {
  source = "${local.base_source_url}"
}

include "root" {
  path = find_in_parent_folders()
}

# ---------------------------------------------------------------------------------------------------------------------
# Locals are named constants that are reusable within the configuration.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment

  # Expose the base source URL so different versions of the module can be deployed in different environments. This will
  # be used to construct the terraform block in the child terragrunt configurations.
  base_source_url = "git::git@github.com:Tomczi18/terragruntModules.git//alb"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id            = "temp vpc id"
    public_subnet_ids = ["subnet1", "subnet2"]
  }
}

dependency "ec2-private" {
  config_path = "../ec2-private"
  mock_outputs = {
    ec2_private_instance_ids = ["instance1", "instance2"]
    ec2_private_sg_ids       = ["sg1", "sg2"]
  }
}

dependency "asg" {
  config_path = "../asg"
  mock_outputs = {
    autoscaling_group_id = "asg id"
  }
}

# Inputs are the values demanded by specific module. In this case we providing data in order to create vpc.
inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  asg_id             = dependency.asg.outputs.autoscaling_group_id
  ec2_instaces       = dependency.ec2-private.outputs.ec2_private_instance_ids
  ec2_private_sg_ids = dependency.ec2-private.outputs.ec2_private_sg_ids
  public_subnet_ids  = dependency.vpc.outputs.public_subnet_ids
}

