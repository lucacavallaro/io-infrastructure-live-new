# DNS Zone
dependency "resource_group" {
  config_path = "../../resource_group"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::git@github.com:pagopa/io-infrastructure-modules-new.git//azurerm_private_dns_zone?ref=v2.1.12"
}

inputs = {
  name                = "cstar.pagopa.it"
  resource_group_name = dependency.resource_group.outputs.resource_name

  dns_a_records = [{
    name               = "test"
    ttl                = 3600
    records            = ["10.70.66.5"]
    target_resource_id = null
    },
    {
      name               = "prod"
      ttl                = 3600
      records            = ["10.70.133.6"]
      target_resource_id = null
  }, ]
}
