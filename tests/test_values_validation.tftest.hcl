provider "azurerm" {
  features {}
}

variables {
  resource_group_name = "rg-platform-inttest"
  location            = "EastUS"
  platform_domain     = "intest.nebuly.ai"
    nebuly_credentials = {
      client_id = ""
      client_secret= ""
    }

  # ------ AKS ------ #
  aks_net_profile_service_cidr   = "10.32.0.0/24"
  aks_net_profile_dns_service_ip = "10.32.0.10"
  aks_cluster_admin_object_ids   = []
}

run "values_validation__subnet_aks_nodes" {
  command = plan

  variables {
    # We're provising the existing subnet name without providing an existing vnet: validation should fail. 
    virtual_network_name  = null
    subnet_name_aks_nodes = "my-cool-subnet"
  }

  expect_failures = [
    var.subnet_name_aks_nodes
  ]
}

run "values_validation__subnet_private_endpoints" {
  command = plan

  variables {
    # We're provising the existing subnet name without providing an existing vnet: validation should fail. 
    virtual_network_name  = null
    subnet_name_private_endpoints = "my-cool-subnet"
  }

  expect_failures = [
    var.subnet_name_private_endpoints
  ]
}

