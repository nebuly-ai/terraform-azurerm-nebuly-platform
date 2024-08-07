terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.114"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.12"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.53"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4"
    }
  }
}



# ------ Locals ------ #
locals {
  aks_cluster_name = format("%snebuly", var.resource_prefix)

  current_ip = chomp(data.http.current_ip.response_body)

  postgres_server_name = format("%snebulydb", var.resource_prefix)
  postgres_server_configurations = {
    "azure.extensions" : "vector,pgaudit",
    "shared_preload_libraries" : "pgaudit",
  }

  key_vault_name = format("%snebulykv", var.resource_prefix)

  use_existing_virtual_network          = var.virtual_network_name != null
  use_existing_aks_nodes_subnet         = var.subnet_name_aks_nodes != null
  use_existing_private_endpoints_subnet = var.subnet_name_private_endpoints != null
  use_existing_flexible_postgres_subnet = var.subnet_name_flexible_postgres != null

  virtual_network = (
    local.use_existing_virtual_network ?
    data.azurerm_virtual_network.main[0] :
    azurerm_virtual_network.main[0]
  )
  aks_nodes_subnet = (
    local.use_existing_aks_nodes_subnet ?
    data.azurerm_subnet.aks_nodes[0] :
    azurerm_subnet.aks_nodes[0]
  )
  flexible_postgres_subnet = (
    local.use_existing_flexible_postgres_subnet ?
    data.azurerm_subnet.flexible_postgres[0] :
    azurerm_subnet.flexible_postgres[0]
  )
}




# ------ Data Sources ------ #
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}
data "azurerm_client_config" "current" {
}
data "http" "current_ip" {
  url = "https://ipv4.icanhazip.com"
}
data "azurerm_virtual_network" "main" {
  count = local.use_existing_virtual_network ? 1 : 0

  resource_group_name = var.resource_group_name
  name                = var.virtual_network_name
}
data "azurerm_subnet" "aks_nodes" {
  count = local.use_existing_aks_nodes_subnet ? 1 : 0

  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = data.azurerm_virtual_network.main[0].name
  name                 = var.subnet_name_aks_nodes

  lifecycle {
    precondition {
      condition     = length(data.azurerm_virtual_network.main) > 0
      error_message = "`virtual_network_name` must be provided and must point to a valid virtual network."
    }
  }
}
data "azurerm_subnet" "flexible_postgres" {
  count = local.use_existing_flexible_postgres_subnet ? 1 : 0

  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = data.azurerm_virtual_network.main[0].name
  name                 = var.subnet_name_flexible_postgres

  lifecycle {
    precondition {
      condition     = length(data.azurerm_virtual_network.main) > 0
      error_message = "`virtual_network_name` must be provided and must point to a valid virtual network."
    }
  }
}


# ------ Networking: Networks and Subnets ------ #
resource "azurerm_virtual_network" "main" {
  count = local.use_existing_virtual_network ? 0 : 1

  name                = format("%s-nebuly-vnet", var.resource_prefix)
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  address_space       = var.virtual_network_address_space
}
resource "azurerm_subnet" "aks_nodes" {
  count = local.use_existing_aks_nodes_subnet ? 0 : 1

  name                 = "aks-nodes"
  virtual_network_name = local.virtual_network.name
  resource_group_name  = data.azurerm_resource_group.main.name
  address_prefixes     = var.subnet_address_space_aks_nodes

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.CognitiveServices",
    "Microsoft.KeyVault",
  ]
}
resource "azurerm_subnet" "private_endpints" {
  count = local.use_existing_private_endpoints_subnet ? 0 : 1

  name                 = "private-endpoints"
  virtual_network_name = local.virtual_network.name
  resource_group_name  = data.azurerm_resource_group.main.name
  address_prefixes     = var.subnet_address_space_private_endpoints
}
resource "azurerm_subnet" "flexible_postgres" {
  count = local.use_existing_flexible_postgres_subnet ? 0 : 1

  name                 = "flexible-postgres"
  virtual_network_name = local.virtual_network.name
  resource_group_name  = data.azurerm_resource_group.main.name
  address_prefixes     = var.subnet_address_space_flexible_postgres

  delegation {
    name = "delegation"
    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }
}



# ------ Networking: Private DNS Zones ------ #
resource "azurerm_private_dns_zone" "flexible_postgres" {
  count = var.private_dns_zones.flexible_postgres == null ? 1 : 0

  name                = "${var.resource_prefix}.nebuly.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "flexible_postgres" {
  count = var.private_dns_zones.flexible_postgres == null ? 1 : 0

  name = format(
    "%s-flexible-postgres-%s",
    var.resource_prefix,
    local.virtual_network.name,
  )
  resource_group_name   = data.azurerm_resource_group.main.name
  virtual_network_id    = local.virtual_network.id
  private_dns_zone_name = azurerm_private_dns_zone.flexible_postgres[0].name
}


# ------ Key Vault ------ #
resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  resource_group_name = data.azurerm_resource_group.main.name

  enable_rbac_authorization = true

  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days
  purge_protection_enabled      = var.key_vault_purge_protection_enabled
  public_network_access_enabled = var.key_vault_public_network_access_enabled

  sku_name = lower(var.key_vault_sku_name)

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    virtual_network_subnet_ids = [local.aks_nodes_subnet.id]
    ip_rules                   = var.whitelist_current_ip ? [local.current_ip] : []
  }

  tags = var.tags
}
resource "azurerm_role_assignment" "key_vault_secret_user__aks" {
  scope                = azurerm_key_vault.main.id
  principal_id         = module.aks.cluster_identity.principal_id
  role_definition_name = "Key Vault Secrets User"
}
resource "azurerm_role_assignment" "key_vault_secret_officer__current" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}




# ------ Identity ------ #
resource "azuread_application" "main" {
  display_name     = format("%s.nebuly.platform", var.resource_prefix)
  owners           = [data.azurerm_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg" # default
  identifier_uris  = []
}
resource "azuread_service_principal" "main" {
  client_id                    = azuread_application.main.client_id
  owners                       = [data.azurerm_client_config.current.object_id]
  app_role_assignment_required = true
}
resource "azuread_service_principal_password" "main" {
  service_principal_id = azuread_service_principal.main.id
  end_date_relative    = null
}
resource "azurerm_key_vault_secret" "azuread_application_client_id" {
  key_vault_id = azurerm_key_vault.main.id
  name         = format("%s-azure-client-id", var.resource_prefix)
  value        = azuread_application.main.client_id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}
resource "azurerm_key_vault_secret" "azuread_application_client_secret" {
  key_vault_id = azurerm_key_vault.main.id
  name         = format("%s-azure-client-secret", var.resource_prefix)
  value        = azuread_application.main.client_id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}



# ------ Database Server ------ #
resource "random_password" "postgres_server_admin_password" {
  length           = 16
  special          = true
  override_special = "!#%&*()-_=+[]{}<>?"
}
resource "azurerm_postgresql_flexible_server" "main" {
  name                = local.postgres_server_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  create_mode = "Default"

  administrator_login    = var.postgres_server_admin_username
  administrator_password = random_password.postgres_server_admin_password.result

  sku_name   = "${var.postgres_server_sku.tier}_${var.postgres_server_sku.name}"
  version    = var.postgres_version
  storage_mb = var.postgres_server_max_storage_mb

  backup_retention_days         = var.postgres_server_point_in_time_backup.retention_days
  geo_redundant_backup_enabled  = var.postgres_server_point_in_time_backup.geo_redundant
  public_network_access_enabled = false

  delegated_subnet_id = local.flexible_postgres_subnet.id
  private_dns_zone_id = length(azurerm_private_dns_zone.flexible_postgres) > 0 ? azurerm_private_dns_zone.flexible_postgres[0].id : var.private_dns_zones.flexible_postgres.id

  dynamic "high_availability" {
    for_each = var.postgres_server_high_availability.enabled ? { "" : var.postgres_server_high_availability } : {}
    content {
      mode                      = high_availability.value.mode
      standby_availability_zone = high_availability.value.standby_availability_zone
    }
  }

  maintenance_window {
    day_of_week  = var.postgres_server_maintenance_window.day_of_week
    start_hour   = var.postgres_server_maintenance_window.start_hour
    start_minute = var.postgres_server_maintenance_window.start_minute
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone,
    ]
  }
}
resource "azurerm_postgresql_flexible_server_configuration" "optional_configurations" {
  for_each = var.postgres_server_optional_configurations

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = each.value
}
resource "azurerm_postgresql_flexible_server_configuration" "mandatory_configurations" {
  for_each = local.postgres_server_configurations

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = each.value
}
resource "azurerm_postgresql_flexible_server_database" "auth" {
  name      = "auth"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
resource "azurerm_postgresql_flexible_server_database" "analytics" {
  name      = "analytics"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
resource "azurerm_management_lock" "postgres_server" {
  count = var.postgres_server_lock.enabled ? 1 : 0

  name       = var.postgres_server_lock.name
  scope      = azurerm_postgresql_flexible_server.main.id
  lock_level = "CanNotDelete"
  notes      = var.postgres_server_lock.notes
}
resource "azurerm_monitor_metric_alert" "postgres_server_alerts" {
  for_each = var.postgres_server_alert_rules

  description = each.value.description
  frequency   = each.value.frequency
  window_size = each.value.window_size

  name = format(
    "%s-%s",
    local.postgres_server_name,
    each.key,
  )

  resource_group_name = data.azurerm_resource_group.main.name
  severity            = each.value.severity
  scopes              = [azurerm_postgresql_flexible_server.main.id]

  target_resource_type = "Microsoft.DBforPostgreSQL/flexibleServers"

  action {
    action_group_id    = each.value.action_group_id
    webhook_properties = {}
  }

  dynamic "criteria" {
    for_each = each.value.criteria == null ? {} : { "" : each.value.criteria }
    content {
      aggregation            = criteria.value.aggregation
      metric_name            = criteria.value.metric_name
      metric_namespace       = "Microsoft.DBforPostgreSQL/flexibleServers"
      operator               = criteria.value.operator
      skip_metric_validation = false
      threshold              = criteria.value.threshold
    }
  }

  dynamic "dynamic_criteria" {
    for_each = each.value.dynamic_criteria == null ? {} : { "" : each.value.dynamic_criteria }
    content {
      aggregation       = dynamic_criteria.value.aggregation
      metric_name       = dynamic_criteria.value.metric_name
      metric_namespace  = "Microsoft.DBforPostgreSQL/flexibleServers"
      operator          = dynamic_criteria.value.operator
      alert_sensitivity = dynamic_criteria.value.alert_sensitivity
    }
  }

  tags = var.tags
}
resource "azurerm_key_vault_secret" "postgres_user" {
  name         = "${var.resource_prefix}-postgres-username"
  value        = var.postgres_server_admin_username
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "${var.resource_prefix}-postgres-password"
  value        = random_password.postgres_server_admin_password.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}




# ------ Azure OpenAI ------ #
locals {
  azure_openai_account_name = format("%snebuly", var.resource_prefix)
}
resource "azurerm_cognitive_account" "main" {
  name                = local.azure_openai_account_name
  location            = var.azure_openai_location
  resource_group_name = data.azurerm_resource_group.main.name
  kind                = "OpenAI"

  sku_name              = "S0"
  custom_subdomain_name = local.azure_openai_account_name

  network_acls {
    default_action = "Deny"

    virtual_network_rules {
      subnet_id = local.aks_nodes_subnet.id
    }
  }

  tags = var.tags
}
resource "azurerm_cognitive_deployment" "gpt_4_turbo" {
  cognitive_account_id = azurerm_cognitive_account.main.id
  name                 = "gpt-4-turbo"
  rai_policy_name      = "Microsoft.Default"

  model {
    format  = "OpenAI"
    name    = "gpt-4"
    version = "turbo-2024-04-09"
  }
  scale {
    type     = "Standard"
    capacity = var.azure_openai_rate_limits.gpt_4
  }
}
resource "azurerm_cognitive_deployment" "gpt_4o_mini" {
  cognitive_account_id = azurerm_cognitive_account.main.id
  name                 = "gpt-4o-mini"
  rai_policy_name      = "Microsoft.Default"

  model {
    format  = "OpenAI"
    name    = "gpt-4o-mini"
    version = "2024-07-18"
  }
  scale {
    type     = "Standard"
    capacity = var.azure_openai_rate_limits.gpt_4o_mini
  }
}
resource "azurerm_key_vault_secret" "azure_openai_api_key" {
  name         = "${var.resource_prefix}-openai-api-key"
  value        = azurerm_cognitive_account.main.primary_access_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}




# ------ Model Registry ------ #
resource "azurerm_storage_account" "main" {
  name                = format("%s%s", var.resource_prefix, "models")
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  public_network_access_enabled = true # TODO
  is_hns_enabled                = false

  network_rules {
    default_action             = "Deny"
    ip_rules                   = var.whitelist_current_ip ? [local.current_ip] : []
    virtual_network_subnet_ids = [local.aks_nodes_subnet.id]
  }

  tags = var.tags
}
resource "azurerm_storage_container" "models" {
  storage_account_name = azurerm_storage_account.main.name
  name                 = "ai-models"
}
resource "azurerm_role_assignment" "storage_container_models__data_contributor" {
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.aks.kubelet_identity[0].object_id
  scope                = azurerm_storage_container.models.resource_manager_id
}




# ------ AKS ------ #
resource "tls_private_key" "aks" {
  algorithm = "RSA" # Azure VMs currently do not support ECDSA
  rsa_bits  = "4096"
}
locals {
  aks_api_server_allowed_ip_addresses = (
    var.whitelist_current_ip ?
    merge({ "current-ip" : local.current_ip }, var.aks_api_server_allowed_ip_addresses) :
    var.aks_api_server_allowed_ip_addresses
  )
}
module "aks" {
  source  = "Azure/aks/azurerm"
  version = "9.1.0"

  prefix              = var.resource_prefix
  cluster_name        = local.aks_cluster_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  kubernetes_version   = var.aks_kubernetes_version
  orchestrator_version = var.aks_kubernetes_version
  sku_tier             = var.aks_sku_tier


  vnet_subnet_id             = local.aks_nodes_subnet.id
  net_profile_service_cidr   = var.aks_net_profile_service_cidr
  net_profile_dns_service_ip = var.aks_net_profile_dns_service_ip
  api_server_authorized_ip_ranges = [
    for _, ip in local.aks_api_server_allowed_ip_addresses : "${ip}/32"
  ]

  rbac_aad_admin_group_object_ids   = var.aks_cluster_admin_object_ids
  rbac_aad_managed                  = true
  role_based_access_control_enabled = true
  local_account_disabled            = true
  private_cluster_enabled           = false

  log_analytics_workspace = var.aks_log_analytics_workspace

  temporary_name_for_rotation = "systemback"

  os_disk_size_gb              = var.aks_sys_pool.disk_size_gb
  os_disk_type                 = var.aks_sys_pool.disk_type
  enable_auto_scaling          = var.aks_sys_pool.enable_auto_scaling
  agents_size                  = var.aks_sys_pool.vm_size
  agents_min_count             = var.aks_sys_pool.agents_min_count
  agents_max_count             = var.aks_sys_pool.agents_max_count
  agents_count                 = var.aks_sys_pool.nodes_count
  agents_max_pods              = var.aks_sys_pool.nodes_max_pods
  agents_pool_name             = var.aks_sys_pool.name
  agents_availability_zones    = var.aks_sys_pool.availability_zones
  only_critical_addons_enabled = var.aks_sys_pool.only_critical_addons_enabled
  agents_type                  = "VirtualMachineScaleSets"

  agents_labels = merge(var.aks_sys_pool.nodes_labels, {
    "nodepool" : "defaultnodepool"
  })

  agents_tags = merge(var.aks_sys_pool.nodes_tags, {
    "Agent" : "defaultnodepoolagent"
  })

  network_policy = "azure"
  network_plugin = "azure"

  # We set this to `false` and create the role assignment manually to avoid invalid for_each argument error.
  create_role_assignment_network_contributor = false

  public_ssh_key = tls_private_key.aks.public_key_openssh

  # Plugins
  storage_profile_blob_driver_enabled = true
  key_vault_secrets_provider_enabled  = true
  azure_policy_enabled                = true

  tags = var.tags
}
resource "time_sleep" "wait_aks_creation" {
  create_duration = "30s"

  depends_on = [
    module.aks
  ]
}
# The AKS cluster identity has the Contributor role on the AKS second resource group (MC_myResourceGroup_myAKSCluster_eastus)
# However when using a custom VNET, the AKS cluster identity needs the Network Contributor role on the VNET subnets
# used by the system node pool and by any additional node pools.
# https://learn.microsoft.com/en-us/azure/aks/configure-kubenet#prerequisites
# https://learn.microsoft.com/en-us/azure/aks/configure-azure-cni#prerequisites
# https://github.com/Azure/terraform-azurerm-aks/issues/178
resource "azurerm_role_assignment" "aks_network_contributor" {
  principal_id         = module.aks.cluster_identity.principal_id
  scope                = local.aks_nodes_subnet.id
  role_definition_name = "Network Contributor"
}
resource "azurerm_kubernetes_cluster_node_pool" "linux_pools" {
  for_each = { for k, v in var.aks_worker_pools : k => v if v.enabled }

  name                  = each.key
  kubernetes_cluster_id = module.aks.aks_id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = local.aks_nodes_subnet.id
  priority              = each.value.priority

  node_count          = each.value.nodes_count
  max_pods            = each.value.max_pods
  min_count           = each.value.enable_auto_scaling ? each.value.nodes_min_count : null
  max_count           = each.value.enable_auto_scaling ? each.value.nodes_max_count : null
  enable_auto_scaling = each.value.enable_auto_scaling

  os_disk_size_gb = each.value.disk_size_gb
  os_disk_type    = each.value.disk_type

  zones       = each.value.availability_zones
  node_taints = each.value.node_taints
  node_labels = each.value.node_labels

  tags = each.value.tags

  lifecycle {
    ignore_changes = [
      node_labels,
      node_taints,
      eviction_policy,
    ]
  }

  depends_on = [
    time_sleep.wait_aks_creation,
  ]
}


# ------ Auth ------ #
resource "tls_private_key" "jwt_signing_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "azurerm_key_vault_secret" "jwt_signing_key" {
  key_vault_id = azurerm_key_vault.main.id
  name         = format("%s-jwt-signing-key", var.resource_prefix)
  value        = tls_private_key.jwt_signing_key.private_key_pem

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}



# ------ Post provisioning ------ #
locals {
  secret_provider_class_name        = "nebuly-platform"
  secret_provider_class_secret_name = "nebuly-platform-credentials"

  # k8s secrets keys
  k8s_secret_key_db_username         = "db-username"
  k8s_secret_key_db_password         = "db-password"
  k8s_secret_key_jwt_signing_key     = "jwt-signing-key"
  k8s_secret_key_openai_api_key      = "openai-api-key"
  k8s_secret_key_azure_client_id     = "azure-client-id"
  k8s_secret_key_azure_client_secret = "azure-client-secret"

  helm_values = templatefile(
    "${path.module}/templates/helm-values.tpl.yaml",
    {
      platform_domain = var.platform_domain

      openai_endpoint               = azurerm_cognitive_account.main.endpoint
      openai_frustration_deployment = azurerm_cognitive_deployment.gpt_4_turbo.name

      secret_provider_class_name        = local.secret_provider_class_name
      secret_provider_class_secret_name = local.secret_provider_class_secret_name

      k8s_secret_key_db_username     = local.k8s_secret_key_db_username
      k8s_secret_key_db_password     = local.k8s_secret_key_db_password
      k8s_secret_key_jwt_signing_key = local.k8s_secret_key_jwt_signing_key
      k8s_secret_key_openai_api_key  = local.k8s_secret_key_openai_api_key

      postgres_server_url              = azurerm_postgresql_flexible_server.main.fqdn
      postgres_auth_database_name      = azurerm_postgresql_flexible_server_database.auth.name
      postgres_analytics_database_name = azurerm_postgresql_flexible_server_database.analytics.name
    },
  )
  secret_provider_class = templatefile(
    "${path.module}/templates/secret-provider-class.tpl.yaml",
    {
      secret_provider_class_name        = local.secret_provider_class_name
      secret_provider_class_secret_name = local.secret_provider_class_secret_name

      key_vault_name          = azurerm_key_vault.main.name
      tenant_id               = data.azurerm_client_config.current.tenant_id
      aks_managed_identity_id = try(module.aks.key_vault_secrets_provider.secret_identity[0].object_id, "TODO")

      secret_name_jwt_signing_key     = azurerm_key_vault_secret.jwt_signing_key.name
      secret_name_db_username         = azurerm_key_vault_secret.postgres_user.name
      secret_name_db_password         = azurerm_key_vault_secret.postgres_password.name
      secret_name_openai_api_key      = azurerm_key_vault_secret.azure_openai_api_key.name
      secret_name_azure_client_id     = azurerm_key_vault_secret.azuread_application_client_id.name
      secret_name_azure_client_secret = azurerm_key_vault_secret.azuread_application_client_secret.name

      k8s_secret_key_db_username         = local.k8s_secret_key_db_username
      k8s_secret_key_db_password         = local.k8s_secret_key_db_password
      k8s_secret_key_jwt_signing_key     = local.k8s_secret_key_jwt_signing_key
      k8s_secret_key_openai_api_key      = local.k8s_secret_key_openai_api_key
      k8s_secret_key_azure_client_id     = local.k8s_secret_key_azure_client_id
      k8s_secret_key_azure_client_secret = local.k8s_secret_key_azure_client_secret
    },
  )
}

