output "helm_values" {
  value       = local.helm_values
  sensitive   = true
  description = <<EOT
  The `values.yaml` file for installing Nebuly with Helm.

  The default standard configuration is used, which uses Nginx as ingress controller and exposes the application to the Internet. This configuration can be customized according to specific needs.
  EOT
}
output "helm_values_bootstrap" {
  value       = local.helm_values_bootstrap
  sensitive   = true
  description = <<EOT
  The `bootrap.values.yaml` file for installing the Nebuly Azure Boostrap chart with Helm.
  EOT
}
output "secret_provider_class" {
  value       = local.secret_provider_class
  sensitive   = true
  description = "The `secret-provider-class.yaml` file to make Kubernetes reference the secrets stored in the Key Vault."
}

output "aks_get_credentials" {
  description = "Command for getting the credentials for connecting to the provisioned AKS cluster."
  value       = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${module.aks.aks_name}"
}

output "azurerm_kubernetes_cluster" {
  description = "The AKS cluster resource."
  value = {
    name = module.aks.aks_name
    id   = module.aks.aks_id
  }
}
output "azurerm_key_vault" {
  description = "The Key Vault resource."
  value       = azurerm_key_vault.main
  sensitive   = true
}
output "azurerm_postgresql_flexible_server" {
  description = "The Flexible Server for PostgreSQL resource."
  value       = azurerm_postgresql_flexible_server.main
  sensitive   = true
}
output "postgres_server_admin" {
  description = "The administrator login for the PostgreSQL server."
  value = {
    login    = var.postgres_server_admin_username
    password = random_password.postgres_server_admin_password.result
  }
  sensitive = true
}
output "postgres_entra_access" {
  description = "Resolved Microsoft Entra access configuration for the PostgreSQL server."
  value = local.postgres_entra_access_enabled ? {
    enabled                    = true
    entra_admin_principal_name = var.postgres_entra_access.entra_admin.principal_name
    reader_groups              = local.postgres_entra_reader_groups
    writer_groups              = local.postgres_entra_writer_groups
    databases                  = local.postgres_entra_databases
  } : null
}
output "postgres_entra_grants_sql" {
  description = "SQL statements used to bootstrap Entra principals and grants (for audit and troubleshooting)."
  value       = local.postgres_entra_grants_sql
  sensitive   = false
}
output "postgres_entra_connection_notes" {
  description = "Notes for connecting to PostgreSQL with Microsoft Entra authentication."
  value       = local.postgres_entra_connection_notes
}
