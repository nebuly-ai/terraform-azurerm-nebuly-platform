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
    nebuly_credentials = {
      client_id = ""
      client_secret= ""
    }

    # ------ Okta SSO ------ #
    okta_sso_credentials = {
      issuer : "my-issuer"
      client_id : "my-client-id"
      client_secret : "my-client-secret"
    }

    # ------ Networking ------#
    virtual_network_name  = run.setup.azurerm_virtual_network.name
    subnet_name_aks_nodes = run.setup.azurerm_subnet.name

    # ------ AKS ------ #
    aks_cluster_admin_group_object_ids   = []
  }
}
