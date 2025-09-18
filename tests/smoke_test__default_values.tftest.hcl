provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
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
