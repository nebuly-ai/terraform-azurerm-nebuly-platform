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

# ------ Data Sources ------ #
data "azuread_group" "engineering" {
  display_name = "nebuly-engineering"
}
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}
locals {
  my_ip = chomp(data.http.my_ip.response_body)
}

module "platform" {
  source = "../../"

  location            = var.location
  resource_group_name = var.resource_group_name
  platform_domain     = "platform.azure.testing"

  postgres_server_sku = {
    tier = "GP"
    name = "Standard_D2ads_v5"
  }

  key_vault_public_network_access_enabled = true
  key_vault_network_acls = {
    ip_rules                   = [local.my_ip]
    virtual_network_subnet_ids = []
  }

  aks_cluster_admin_object_ids = [data.azuread_group.engineering.id]
  resource_prefix              = var.resource_prefix

  tags = var.tags
}

