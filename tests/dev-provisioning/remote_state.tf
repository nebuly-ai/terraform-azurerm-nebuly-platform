 terraform {
      backend "azurerm" {
        resource_group_name  = "rg-shared"
        storage_account_name = "nbllabtfstatessa"
        container_name       = "rg-platform-inttest-tfstate"
        key                  = "tfstate"
      }
    }
