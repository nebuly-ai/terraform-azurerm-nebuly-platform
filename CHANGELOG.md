# Changelog

## v0.17.1

- Fix private DNS zone for web-app routing
- Fix ingress class name in helm_values when web app routing is enabled

## v0.17.0

- Support private AKS cluster

## v0.16.1

- Fix resource count

## v0.16.0

- Enable optional web app routing add-on

## v0.15.0

- Optional Key Vault secrets
- Optional Storage Containers

## v0.14.0

- Private Endpoint fixes (use private endpoints subnet instead of AKS)

## v0.13.0

- Support Azure OpenAI Private Endpoints

## v0.12.0

- Support private DNS zones links

## v0.11.0

- Make AzureAD application creation optional

## v0.10.0

- Support overlay network plugin for AKS
- Update default Kubernetes version to 1.31.5

## v0.9.0

- Remove T4 AKS node pool
- Make Azure AD groups creation optional

## v0.8.0

- Add backups storage
- Update default Kubernetes version to 1.31.3

## v0.7.0

- Allow resource suffix for custom resource names

## v0.6.0

- Support network in different resource groups

## v0.5.0

- Rename `aks_cluster_admin_object_ids` to `aks_cluster_admin_group_object_ids`
- Add variable `aks_cluster_admin_users`
