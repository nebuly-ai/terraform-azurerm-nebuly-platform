# Nebuly Platform Example - Basic usage

This directory shows an example of Terraform code that uses the
[terraform-azurerm-nebuly-platform](https://github.com/nebuly-ai/terraform-azurerm-nebuly-platform) module.

In this example, all default settings are applied, resulting in the creation of a new virtual network to which all resources will be linked.

The Azure Key Vault for storing secrets and the Azure Storage Account for storing Nebuly's LLMs will only be accessible from the IP address
of the current Terraform provisioner. This allows you to run terraform apply without having to setup a VPN.

To modify this behavior, you can set `whitelist_current_ip=false` as an input.
To whitelist more IP address, you can specify them in the input variable `whitelisted_ips`.
