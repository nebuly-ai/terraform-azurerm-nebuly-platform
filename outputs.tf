output "helm_values" {
  value       = local.helm_values
  sensitive   = true
  description = <<EOT
  The `values.yaml` file for installing Nebuly with Helm.

  The default standard configuration is used, which uses Nginx as ingress controller and exposes the application to the Internet. This configuration can be customized according to specific needs.
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
