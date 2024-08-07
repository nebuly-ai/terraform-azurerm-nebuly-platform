provider "azurerm" {
  features {}
}

run "smoke_test_plan__default_values" {
  command = plan

  variables {
    resource_group_name = "rg-platform-inttest"
    location            = "EastUS"
    platform_domain     = "intest.nebuly.ai"

    # ------ AKS ------ #
    aks_cluster_admin_object_ids   = []
  }
}
