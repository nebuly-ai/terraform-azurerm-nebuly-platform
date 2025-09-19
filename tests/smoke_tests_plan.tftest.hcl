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

test {
  parallel = true
}

run "smoke_test_plan__default_values" {
  command = plan

  variables {
    resource_group_name = var.resource_group_name
    location            = "EastUS"
    platform_domain     = "intest.nebuly.ai"
    nebuly_credentials = {
      client_id     = ""
      client_secret = ""
    }

    # ------ AKS ------ #
    aks_cluster_admin_group_object_ids = []
    aks_cluster_admin_users            = []
  }
}

run "smoke_test_plan__existing_networks" {
  command = plan

  variables {
    resource_group_name = var.resource_group_name
    location            = "EastUS"
    platform_domain     = "intest.nebuly.ai"
    nebuly_credentials = {
      client_id     = ""
      client_secret = ""
    }

    # ------ Networking ------#
    virtual_network = {
      name                = run.setup.azurerm_virtual_network.name
      resource_group_name = var.resource_group_name
    }
    subnet_name_aks_nodes = run.setup.azurerm_subnet.name

    # ------ AKS ------ #
    aks_cluster_admin_group_object_ids = []
    aks_cluster_admin_users            = []
  }
}

run "smoke_test_plan__okta_sso" {
  command = plan

  variables {
    resource_group_name = var.resource_group_name
    location            = "EastUS"
    platform_domain     = "intest.nebuly.ai"
    nebuly_credentials = {
      client_id     = ""
      client_secret = ""
    }

    # ------ Okta SSO ------ #
    okta_sso_credentials = {
      issuer : "my-issuer"
      client_id : "my-client-id"
      client_secret : "my-client-secret"
    }

    # ------ Networking ------#
    virtual_network = {
      name                = run.setup.azurerm_virtual_network.name
      resource_group_name = var.resource_group_name
    }
    subnet_name_aks_nodes = run.setup.azurerm_subnet.name

    # ------ AKS ------ #
    aks_cluster_admin_group_object_ids = []
    aks_cluster_admin_users            = []
  }
}

run "smoke_test_plan__private_endpoints__no_create_no_link" {
  command = plan

  variables {
    resource_group_name = var.resource_group_name
    location            = "EastUS"
    platform_domain     = "intest.nebuly.ai"
    nebuly_credentials = {
      client_id     = ""
      client_secret = ""
    }

    private_dns_zones = {
      flexible_postgres = {
        name                = run.setup.azurerm_private_dns_zone.flexible_postgres.name
        resource_group_name = run.setup.azurerm_private_dns_zone.flexible_postgres.resource_group_name
        create              = false
        link_vnet           = false
      }
      openai = {
        create              = false
        link_vnet           = false
        link_dns_zone_group = false
      }
      key_vault = {
        create              = false
        link_vnet           = false
        link_dns_zone_group = false
      }
      blob = {
        create              = false
        link_vnet           = false
        link_dns_zone_group = false
      }
      dfs = {
        create              = false
        link_vnet           = false
        link_dns_zone_group = false
      }
    }

    # ------ AKS ------ #
    aks_cluster_admin_group_object_ids = []
    aks_cluster_admin_users            = []
  }
}

run "smoke_test_plan__private_endpoints__postgres_id" {
  command = plan

  variables {
    resource_group_name = var.resource_group_name
    location            = "EastUS"
    platform_domain     = "intest.nebuly.ai"
    nebuly_credentials = {
      client_id     = ""
      client_secret = ""
    }

    private_dns_zones = {
      flexible_postgres = {
        id        = run.setup.azurerm_private_dns_zone.flexible_postgres.id
        create    = false
        link_vnet = false
      }
      openai = {
        create              = false
        link_vnet           = false
        link_dns_zone_group = false
      }
      key_vault = {
        create              = false
        link_vnet           = false
        link_dns_zone_group = false
      }
      blob = {
        create              = false
        link_vnet           = false
        link_dns_zone_group = false
      }
      dfs = {
        create              = false
        link_vnet           = false
        link_dns_zone_group = false
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
        name                = run.setup.azurerm_private_dns_zone.flexible_postgres.name
        resource_group_name = run.setup.azurerm_private_dns_zone.flexible_postgres.resource_group_name
        create              = false
        link_vnet           = true
      }
      openai = {
        name                = run.setup.azurerm_private_dns_zone.openai.name
        resource_group_name = run.setup.azurerm_private_dns_zone.openai.resource_group_name
        create              = false
        link_vnet           = true
      }
      key_vault = {
        name                = run.setup.azurerm_private_dns_zone.key_vault.name
        resource_group_name = run.setup.azurerm_private_dns_zone.key_vault.resource_group_name
        create              = false
        link_vnet           = true
      }
      blob = {
        name                = run.setup.azurerm_private_dns_zone.blob.name
        resource_group_name = run.setup.azurerm_private_dns_zone.blob.resource_group_name
        create              = false
        link_vnet           = true
      }
      dfs = {
        name                = run.setup.azurerm_private_dns_zone.dfs.name
        resource_group_name = run.setup.azurerm_private_dns_zone.dfs.resource_group_name
        create              = false
        link_vnet           = true
      }
    }

    # ------ AKS ------ #
    aks_cluster_admin_group_object_ids = []
    aks_cluster_admin_users            = []
  }
}

run "values_validation__subnet_aks_nodes" {
  command = plan

  variables {
    resource_group_name = "rg-platform-inttest"
    location            = "EastUS"
    platform_domain     = "intest.nebuly.ai"
    nebuly_credentials = {
      client_id     = ""
      client_secret = ""
    }

    # ------ AKS ------ #
    aks_net_profile_service_cidr       = "10.32.0.0/24"
    aks_net_profile_dns_service_ip     = "10.32.0.10"
    aks_cluster_admin_group_object_ids = []
    aks_cluster_admin_users            = []

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
    resource_group_name = "rg-platform-inttest"
    location            = "EastUS"
    platform_domain     = "intest.nebuly.ai"
    nebuly_credentials = {
      client_id     = ""
      client_secret = ""
    }

    # ------ AKS ------ #
    aks_net_profile_service_cidr       = "10.32.0.0/24"
    aks_net_profile_dns_service_ip     = "10.32.0.10"
    aks_cluster_admin_group_object_ids = []
    aks_cluster_admin_users            = []

    # We're provising the existing subnet name without providing an existing vnet: validation should fail. 
    virtual_network_name          = null
    subnet_name_private_endpoints = "my-cool-subnet"
  }

  expect_failures = [
    var.subnet_name_private_endpoints
  ]
}

