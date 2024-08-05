output "helm_values" {
  value       = local.helm_values
  sensitive   = true
  description = "The values.yaml file for installing Nebuly on the provisioned resources."
}
