terraform {
  required_version = ">= 1.0"

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
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.0"
    }
  }
}


# ------ Locals ------ #
locals {
  aks_cluster_name = format("%snebuly", var.resource_prefix)


  postgres_server_name = format("%snebuly", var.resource_prefix)
  postgres_server_configurations = {
    "azure.extensions" : "vector,pgaudit",
    "shared_preload_libraries" : "pgaudit",
  }
  postgres_databases = toset([
    "analytics",
    "auth",
  ])


  key_vault_name = format("%snebulykv", var.resource_prefix)
}




# ------ Data Sources ------ #
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}
data "azurerm_client_config" "current" {
}
data "azurerm_subnet" "aks_nodes" {
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = var.aks_nodes_virtual_network_name
  name                 = var.aks_nodes_subnet_name
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

  dynamic "network_acls" {
    for_each = var.key_vault_network_acls == null ? {} : { "" : "" }
    content {
      bypass                     = var.network_acls.bypass
      default_action             = var.network_acls.default_action
      ip_rules                   = var.network_acls.ip_rules
      virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
    }
  }

  tags = var.tags
}
resource "azurerm_private_endpoint" "key_vault" {
  for_each = var.key_vault_private_endpoints

  name                = "${azurerm_key_vault.main.name}-${each.key}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = each.value.subnet_id


  private_service_connection {
    name                           = "${azurerm_key_vault.main.name}-${each.key}-pe"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name = "privatelink-vaultcore-azure-net"
    private_dns_zone_ids = [
      var.key_vault_private_dns_zone.id
    ]
  }

  tags = var.tags
}
resource "azurerm_role_assignment" "key_vault_secret_user__aks" {
  scope                = azurerm_key_vault.main.id
  principal_id         = "" # TODO
  role_definition_name = "Key Vault Secrets User"
}
resource "azurerm_role_assignment" "key_vault_secret_officer__current" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}


# ------ External Secrets ------ #
resource "azurerm_key_vault_secret" "openai_api_key" {
  key_vault_id = azurerm_key_vault.main.id
  name         = "${var.resource_prefix}-openai-api-key"
  value        = var.openai_api_key
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
  public_network_access_enabled = var.postgres_server_networking.public_network_access_enabled

  delegated_subnet_id = var.postgres_server_networking.delegated_subnet_id
  private_dns_zone_id = var.postgres_server_networking.private_dns_zone_id

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
resource "azurerm_postgresql_flexible_server_firewall_rule" "main" {
  for_each = { for o in var.postgres_server_networking.allowed_ip_ranges : o.name => o }

  name             = each.key
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}
resource "azurerm_postgresql_flexible_server_database" "main" {
  for_each = local.postgres_databases

  name      = each.value
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
resource "azurerm_key_vault_secret" "postgres_users" {
  for_each = local.postgres_databases

  name         = "${var.resource_prefix}-${each.key}-postgres-user"
  value        = var.postgres_server_admin_username
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}
resource "azurerm_key_vault_secret" "postgres_passwords" {
  for_each = local.postgres_databases

  name         = "${var.resource_prefix}-${each.key}-postgres-password"
  value        = random_password.postgres_server_admin_password.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}




# ------ AKS ------ #
resource "tls_private_key" "aks" {
  algorithm = "RSA" # Azure VMs currently do not support ECDSA
  rsa_bits  = "4096"
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


  vnet_subnet_id             = data.azurerm_subnet.aks_nodes.id
  net_profile_service_cidr   = var.aks_net_profile_service_cidr
  net_profile_dns_service_ip = var.aks_net_profile_dns_service_ip
  api_server_authorized_ip_ranges = [
    for _, ip in var.aks_api_server_allowed_ip_addresses : "${ip}/32"
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

  # Azure CNI requrires the cluster identity to have at least Network Contributor
  # permissions on the subnet. See:
  # https://learn.microsoft.com/en-us/azure/aks/configure-azure-cni
  create_role_assignment_network_contributor = true

  public_ssh_key = tls_private_key.aks.public_key_openssh

  # Plugins
  storage_profile_blob_driver_enabled = true
  key_vault_secrets_provider_enabled  = true
  azure_policy_enabled                = true

  tags = var.tags
}
resource "azurerm_kubernetes_cluster_node_pool" "linux_pools" {
  for_each = { for k, v in var.aks_worker_pools : k => v if v.enabled }

  name                  = each.key
  kubernetes_cluster_id = module.aks.aks_id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = data.azurerm_subnet.aks_nodes.id
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
}
