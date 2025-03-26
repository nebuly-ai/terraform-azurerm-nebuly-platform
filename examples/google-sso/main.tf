# ------- Terraform Setup ------ #
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


module "platform" {
  source  = "nebuly-ai/nebuly-platform/azurerm"
  version = ">=0.2.10"

  location            = "EastUS"
  resource_group_name = "my-resource-group"
  platform_domain     = "platform.azure.testing"
  resource_prefix     = "myprefix"

  # Credentials provided by Nebuly for activating your Platform installation.
  nebuly_credentials = {
    client_id     = "<your-client-id>"
    client_secret = "<your-client-secret>"
  }
  # Google SSO configuration (see README.md).
  google_sso = {
    client_id     = "<your-google-client-id>"
    client_secret = "<your-google-client-secret>"
    role_mapping = {
      "viewer" = "<viewer-group-email>"
      "member" = "<member-group-email>"
      "admin"  = "<admin-group-email>"
    }
  }

  key_vault_public_network_access_enabled = true
  aks_cluster_admin_group_object_ids = [
    # Add here your AAD Groups Object IDs.
    # These identities will be able to access the created AKS cluster as "Cluster Admin".
  ]
  aks_cluster_admin_users = [
    # Add here your User Principal Names (e.g. email addresses).
    # These identities will be able to access the created AKS cluster as "Cluster Admin".
  ]

  tags = {
    "env" : "dev"
    "managed-by" : "terraform"
  }
}


# ------ Outputs ------ #
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
