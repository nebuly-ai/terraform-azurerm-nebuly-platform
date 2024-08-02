terraform {
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

variable "location" {
  type = string
}
variable "tags" {
  type = map(any)
}
variable "resource_prefix" {
  type = string
}


# ----------- Data Sources ----------- #
data "azurerm_resource_group" "main" {
  name = "rg-platform-inttest"
}

# ----------- Resources ----------- #
resource "azurerm_virtual_network" "main" {
  name = format("%s-integration-test", var.resource_prefix)

  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  location            = var.location

  tags = var.tags
}
resource "azurerm_subnet" "main" {
  name = "aks-nodes"

  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
  resource_group_name  = data.azurerm_resource_group.main.name
}


# ----------- Outputs ----------- #
output "azurerm_virtual_network" {
  value = azurerm_virtual_network.main
}
output "azurerm_subnet" {
  value = azurerm_subnet.main
}
