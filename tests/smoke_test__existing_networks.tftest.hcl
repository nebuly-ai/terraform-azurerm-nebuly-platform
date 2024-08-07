provider "azurerm" {
  features {}
}

run "setup" {
  module {
    source = "./tests/setup"
  }

  variables {
    location = "EastUS"
  }
}

run "smoke_test_plan__existing_networks" {
  command = plan

  variables {
    resource_group_name = "rg-platform-inttest"
    location            = "EastUS"
    platform_domain     = "intest.nebuly.ai"

    # ------ Networking ------#
    virtual_network_name  = run.setup.azurerm_virtual_network.name
    subnet_name_aks_nodes = run.setup.azurerm_subnet.name

    # ------ Key Vault ------ #
    key_vault_public_network_access_enabled = false

    # ------ AKS ------ #
    aks_cluster_admin_object_ids   = []
  }
}
