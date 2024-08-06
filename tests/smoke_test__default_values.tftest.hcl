provider "azurerm" {
  features {}
}

run "smoke_test_plan__default_values" {
  command = plan

  variables {
    resource_group_name = "rg-platform-inttest"
    location            = "EastUS"
    platform_domain     = "intest.nebuly.ai"

    # ------ PostgreSQL Database  ------ #
    postgres_server_networking = {}

    # ------ Key Vault ------ #
    key_vault_public_network_access_enabled = true

    # ------ AKS ------ #
    aks_net_profile_service_cidr   = "10.32.0.0/24"
    aks_net_profile_dns_service_ip = "10.32.0.10"
    aks_cluster_admin_object_ids   = []
  }
}
