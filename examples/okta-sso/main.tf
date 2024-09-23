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
  source  = "nebuly-ai/nebuly-platform/azure"
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
  # Okta SSO configuration (see README.md).
  okta_sso = {
    client_id     = "<your-okta-client-id>"
    client_secret = "<your-okta-client-secret>"
    issuer        = "<your-okta-issuer>"
  }

  key_vault_public_network_access_enabled = true
  aks_cluster_admin_object_ids = [
    # Add here your AAD Groups, users, service principals, etc.
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
