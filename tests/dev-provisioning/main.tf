terraform {
  required_version = ">=1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.114"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.53"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.6"
    }
  }
}

provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}


# ------ Variables ------ #
variable "resource_prefix" {
  type = string
}
variable "client_id" {
  type = string
}
variable "subscription_id" {
  type = string
}
variable "tenant_id" {
  type = string
}
variable "client_secret" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "tags" {
  type = map(any)
}
variable "location" {
  type = string
}
variable "nebuly_credentials" {
  type = object({
    client_id     = string
    client_secret = string
  })
}

# ------ Data Sources ------ #
data "azuread_group" "engineering" {
  display_name = "nebuly-engineering"
}

module "platform" {
  source = "../../"

  location            = var.location
  resource_group_name = var.resource_group_name
  platform_domain     = "platform.azure.testing.nebuly.com"
  nebuly_credentials  = var.nebuly_credentials

  postgres_server_sku = {
    tier = "B"
    name = "Standard_B2ms"
  }
  postgres_server_high_availability = {
    enabled = false
  }
  postgres_override_name = "nbltstnebulydb3"

  aks_network_plugin_mode = "overlay"
  subnet_address_space_aks_nodes = ["10.0.0.0/28"]

  azure_openai_location = "EastUS"
  azure_openai_deployment_gpt4o = {
    rate_limit = 1
  }
  azure_openai_deployment_gpt4o_mini = {
    rate_limit = 1
    enabled    = false
  }

  aks_sku_tier = "Standard"

  key_vault_public_network_access_enabled = true

  aks_cluster_admin_group_object_ids = [data.azuread_group.engineering.object_id]
  aks_cluster_admin_users            = ["m.zanotti@nebuly.ai"]
  resource_prefix                    = var.resource_prefix

  tags = var.tags
}


output "secret_provider_class" {
  value     = module.platform.secret_provider_class
  sensitive = true
}
output "helm_values" {
  value     = module.platform.helm_values
  sensitive = true
}
output "helm_values_bootstrap" {
  value     = module.platform.helm_values_bootstrap
  sensitive = true
}
output "aks_get_credentials" {
  value = module.platform.aks_get_credentials
}
