provider "azurerm" {
  features {}
}

run "smoke_test_plan__private_endpoints__no_create_no_link" {
  command = plan

  variables {
    resource_group_name = "rg-platform-inttest"
    location            = "EastUS"
    platform_domain     = "intest.nebuly.ai"
    nebuly_credentials = {
      client_id     = ""
      client_secret = ""
    }

    private_dns_zones = {
      flexible_postgres = {
        create = false
        link_vnet = false
      }
      openai = {
        create = false
        link_vnet = false
      }
      key_vault = {
        create = false
        link_vnet = false
      }
      blob = {
        create = false
        link_vnet = false
      }
      dfs = {
        create = false
        link_vnet = false
      }
    }

    # ------ AKS ------ #
    aks_cluster_admin_group_object_ids = []
    aks_cluster_admin_users            = []
  }
}
