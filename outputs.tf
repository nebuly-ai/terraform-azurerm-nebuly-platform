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
  description = "The `secret-provider-class.yaml` file for referencing from Kubernetes the secrets stored in the Key Vault."
}
