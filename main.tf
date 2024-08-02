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
  }
}

# ------ Locals ------ #
locals {
  postgres_server_name = format("%snebulyplatform", var.resource_prefix)
  postgres_server_configurations = {
    "azure.extensions" : "vector,pgaudit",
    "shared_preload_libraries" : "pgaudit",
  }
  postgres_databases = toset([
    "analytics",
    "auth",
  ])
}

# ------ Data Sources ------ #
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
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
      high_availability.0.standby_availability_zone,
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
