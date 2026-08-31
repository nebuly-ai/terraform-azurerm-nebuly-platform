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

  aks_network_plugin_mode        = "overlay"
  subnet_address_space_aks_nodes = ["10.0.0.0/28"]

  azure_openai_location = "EastUS"

  aks_sku_tier = "Free"
  aks_kubernetes_version = {
    workers       = "1.36"
    control_plane = "1.36"
  }

  key_vault_public_network_access_enabled = true

  aks_cluster_admin_group_object_ids = [data.azuread_group.engineering.object_id]
  aks_cluster_admin_users            = ["d.cantella@nebuly.ai"]
  resource_prefix                    = var.resource_prefix

  tags = var.tags

  enable_service_endpoints = true

  aks_log_analytics_workspace_enabled = false

  aks_worker_pools = {
    "t4" : {
      vm_size  = "Standard_NC16as_T4_v3"
      priority = "Regular"
      max_pods : 30
      disk_size_gb = 128
      disk_type : "Ephemeral"
      availability_zones = ["1","2","3"]
      tags : {}
      node_taints : [
        "nvidia.com/gpu=:NoSchedule",
      ]
      node_labels : {
        "nebuly.com/accelerator" : "nvidia-tesla-t4"
      }
      # Auto-scaling setttings
      enable_auto_scaling = true
      nodes_count : null
      nodes_min_count = 0
      nodes_max_count = 1
    }
  }
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

output "postgres_entra_access" {
  value = module.platform.postgres_entra_access
}
output "postgres_entra_grants_sql" {
  value = module.platform.postgres_entra_grants_sql
}
output "postgres_entra_connection_notes" {
  value = module.platform.postgres_entra_connection_notes
}
