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
  }
}
