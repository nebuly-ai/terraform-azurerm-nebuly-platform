provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
}

run "setup" {
  module  {
    source = "./tests/setup"
  }

  variables {
    location = "EastUS"
  }
}

run "smoke_test_plan" {
  command = plan

  variables {
    resource_group_name = "rg-platform-inttest"
    location = "EastUS"

    # ------ PostgreSQL Database  ------ #
    postgres_server_networking = { }

    # ------ Key Vault ------ #
    key_vault_public_network_access_enabled = true

    # ------ AKS ------ #
    aks_nodes_virtual_network_name = run.setup.azurerm_virtual_network.name
    aks_nodes_subnet_name = run.setup.azurerm_subnet.name

    aks_net_profile_service_cidr = "10.32.0.0/24" 
    aks_net_profile_dns_service_ip = "10.32.0.10"
    aks_cluster_admin_object_ids = []
  }
}
