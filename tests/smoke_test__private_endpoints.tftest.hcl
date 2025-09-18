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

run "smoke_test_plan__private_endpoints__no_create_yes_link" {
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
        name= run.setup.azurerm_private_dns_zone.flexible_postgres.name
        resource_group_name= run.setup.azurerm_private_dns_zone.flexible_postgres.resource_group_name
        create = false
        link_vnet = true
      }
      openai = {
        name= run.setup.azurerm_private_dns_zone.openai.name
        resource_group_name= run.setup.azurerm_private_dns_zone.openai.resource_group_name
        create = false
        link_vnet = true
      }
      key_vault = {
        name= run.setup.azurerm_private_dns_zone.key_vault.name
        resource_group_name= run.setup.azurerm_private_dns_zone.key_vault.resource_group_name
        create = false
        link_vnet = true
      }
      blob = {
        name= run.setup.azurerm_private_dns_zone.blob.name
        resource_group_name= run.setup.azurerm_private_dns_zone.blob.resource_group_name
        create = false
        link_vnet = true
      }
      dfs = {
        name= run.setup.azurerm_private_dns_zone.dfs.name
        resource_group_name= run.setup.azurerm_private_dns_zone.dfs.resource_group_name
        create = false
        link_vnet = true
      }
    }

    # ------ AKS ------ #
    aks_cluster_admin_group_object_ids = []
    aks_cluster_admin_users            = []
  }
}
