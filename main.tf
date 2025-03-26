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
  }
}



# ------ Locals ------ #
locals {
  aks_cluster_generated_name = (
    var.resource_suffix == null ?
    format("%snebuly", var.resource_prefix) :
    format("%snebuly%s", var.resource_prefix, var.resource_suffix)
  )
  aks_cluster_name = (
    var.aks_override_name == null ? local.aks_cluster_generated_name : var.aks_override_name
  )


  whitelisted_ips = var.whitelisted_ips

  postgres_server_generated_name = (
    var.resource_suffix == null ?
    format("%snebulydb", var.resource_prefix) :
    format("%snebulydb%s", var.resource_prefix, var.resource_suffix)
  )
  postgres_server_name = (
    var.postgres_override_name == null ? local.postgres_server_generated_name : var.postgres_override_name
  )
  postgres_server_configurations = {
    "azure.extensions" : "vector,pgaudit",
    "shared_preload_libraries" : "pgaudit",
  }

  key_vault_generated_name = (
    var.resource_suffix == null ?
    format("%snebulykv", var.resource_prefix) :
    format("%snebulykv%s", var.resource_prefix, var.resource_suffix)
  )
  key_vault_name = (
    var.key_vault_override_name == null ? local.key_vault_generated_name : var.key_vault_override_name
  )

  use_existing_virtual_network          = var.virtual_network != null
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
  private_endpoints_subnet = (
    local.use_existing_private_endpoints_subnet ?
    data.azurerm_subnet.private_endpoints[0] :
    azurerm_subnet.private_endpoints[0]
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
data "azurerm_virtual_network" "main" {
  count = local.use_existing_virtual_network ? 1 : 0

  resource_group_name = var.virtual_network.resource_group_name
  name                = var.virtual_network.name
}
data "azuread_user" "aks_admins" {
  for_each = var.aks_cluster_admin_users

  user_principal_name = each.value
}
data "azurerm_subnet" "aks_nodes" {
  count = local.use_existing_aks_nodes_subnet ? 1 : 0

  resource_group_name  = data.azurerm_virtual_network.main[0].resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main[0].name
  name                 = var.subnet_name_aks_nodes

  lifecycle {
    precondition {
      condition     = length(data.azurerm_virtual_network.main) > 0
      error_message = "`virtual_network_name` must be provided and must point to a valid virtual network."
    }
  }
}
data "azurerm_subnet" "private_endpoints" {
  count = local.use_existing_private_endpoints_subnet ? 1 : 0

  resource_group_name  = data.azurerm_virtual_network.main[0].resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main[0].name
  name                 = var.subnet_name_private_endpoints

  lifecycle {
    precondition {
      condition     = length(data.azurerm_virtual_network.main) > 0
      error_message = "`virtual_network_name` must be provided and must point to a valid virtual network."
    }
  }
}
data "azurerm_subnet" "flexible_postgres" {
  count = local.use_existing_flexible_postgres_subnet ? 1 : 0

  resource_group_name  = data.azurerm_virtual_network.main[0].resource_group_name
  virtual_network_name = data.azurerm_virtual_network.main[0].name
  name                 = var.subnet_name_flexible_postgres

  lifecycle {
    precondition {
      condition     = length(data.azurerm_virtual_network.main) > 0
      error_message = "`virtual_network_name` must be provided and must point to a valid virtual network."
    }
  }
}
data "azurerm_private_dns_zone" "flexible_postgres" {
  count = var.private_dns_zones.flexible_postgres != null ? 1 : 0

  name                = var.private_dns_zones.flexible_postgres.name
  resource_group_name = var.private_dns_zones.flexible_postgres.resource_group_name
}
data "azurerm_private_dns_zone" "openai" {
  count = var.private_dns_zones.openai != null ? 1 : 0

  name                = var.private_dns_zones.openai.name
  resource_group_name = var.private_dns_zones.openai.resource_group_name
}
data "azurerm_private_dns_zone" "key_vault" {
  count = var.private_dns_zones.key_vault != null ? 1 : 0

  name                = var.private_dns_zones.key_vault.name
  resource_group_name = var.private_dns_zones.key_vault.resource_group_name
}
data "azurerm_private_dns_zone" "blob" {
  count = var.private_dns_zones.blob != null ? 1 : 0

  name                = var.private_dns_zones.blob.name
  resource_group_name = var.private_dns_zones.blob.resource_group_name
}
data "azurerm_private_dns_zone" "dfs" {
  count = var.private_dns_zones.dfs != null ? 1 : 0

  name                = var.private_dns_zones.dfs.name
  resource_group_name = var.private_dns_zones.dfs.resource_group_name
}


# ------ Networking: Networks and Subnets ------ #
resource "azurerm_virtual_network" "main" {
  count = local.use_existing_virtual_network ? 0 : 1

  name = (
    var.resource_suffix == null ?
    format("%s-nebuly-vnet", var.resource_prefix) :
    format("%s-nebuly-%s-vnet", var.resource_prefix, var.resource_suffix)
  )
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

  service_endpoints = var.enable_service_endpoints ? [
    "Microsoft.Storage",
    "Microsoft.CognitiveServices",
    "Microsoft.KeyVault",
    ] : [
    "Microsoft.Storage" # Required by Flexible Postgres
  ]
}
resource "azurerm_subnet" "private_endpoints" {
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
locals {
  private_dns_zones_names = {
    flexible_postgres = var.private_dns_zones.flexible_postgres != null ? var.private_dns_zones.flexible_postgres.name : azurerm_private_dns_zone.flexible_postgres[0].name,
    openai            = var.private_dns_zones.openai != null ? var.private_dns_zones.openai.name : azurerm_private_dns_zone.openai[0].name,
    key_vault         = var.private_dns_zones.key_vault != null ? var.private_dns_zones.key_vault.name : azurerm_private_dns_zone.key_vault[0].name,
    blob              = var.private_dns_zones.blob != null ? var.private_dns_zones.blob.name : azurerm_private_dns_zone.blob[0].name,
    dfs               = var.private_dns_zones.dfs != null ? var.private_dns_zones.dfs.name : azurerm_private_dns_zone.dfs[0].name,
  }
}
# - postgres
resource "azurerm_private_dns_zone" "flexible_postgres" {
  count = var.private_dns_zones.flexible_postgres == null ? 1 : 0

  name                = "${var.resource_prefix}.nebuly.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "flexible_postgres" {
  name = format(
    "%s-flexible-postgres-%s",
    var.resource_prefix,
    local.virtual_network.name,
  )
  resource_group_name   = data.azurerm_resource_group.main.name
  virtual_network_id    = local.virtual_network.id
  private_dns_zone_name = local.private_dns_zones_names.flexible_postgres
}
# - key vault
resource "azurerm_private_dns_zone" "key_vault" {
  count               = var.private_dns_zones.key_vault == null ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.main.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  name = format(
    "%s-key-vault-%s",
    var.resource_prefix,
    local.virtual_network.name,
  )
  resource_group_name   = data.azurerm_resource_group.main.name
  virtual_network_id    = local.virtual_network.id
  private_dns_zone_name = local.private_dns_zones_names.key_vault
}
# - blob
resource "azurerm_private_dns_zone" "blob" {
  count               = var.private_dns_zones.blob == null ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name = format(
    "%s-blob-%s",
    var.resource_prefix,
    local.virtual_network.name,
  )
  resource_group_name   = data.azurerm_resource_group.main.name
  virtual_network_id    = local.virtual_network.id
  private_dns_zone_name = local.private_dns_zones_names.blob
}
# - dfs
resource "azurerm_private_dns_zone" "dfs" {
  count               = var.private_dns_zones.dfs == null ? 1 : 0
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "dfs" {
  name = format(
    "%s-dfs-%s",
    var.resource_prefix,
    local.virtual_network.name,
  )
  resource_group_name   = data.azurerm_resource_group.main.name
  virtual_network_id    = local.virtual_network.id
  private_dns_zone_name = local.private_dns_zones_names.dfs
}
# - openai
resource "azurerm_private_dns_zone" "openai" {
  count               = var.private_dns_zones.openai == null ? 1 : 0
  name                = "privatelink.openai.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  name = format(
    "%s-openai-%s",
    var.resource_prefix,
    local.virtual_network.name,
  )
  resource_group_name   = data.azurerm_resource_group.main.name
  virtual_network_id    = local.virtual_network.id
  private_dns_zone_name = local.private_dns_zones_names.openai
}
# - AKS private ingress controller
resource "azurerm_private_dns_zone" "web_app_routing" {
  count = var.enable_web_routing_addon ? 1 : 0

  name = join(".",
    coalesce(
      length(split(".", var.platform_domain)) > 2 ? slice(split(".", var.platform_domain), 1, length(split(".", var.platform_domain))) : split(".", var.platform_domain)
    )
  )

  resource_group_name = data.azurerm_resource_group.main.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "web_app_routing" {
  count = var.enable_web_routing_addon ? 1 : 0

  name = format(
    "%s-web-app-routing-%s",
    var.resource_prefix,
    local.virtual_network.name,
  )
  resource_group_name   = data.azurerm_resource_group.main.name
  virtual_network_id    = local.virtual_network.id
  private_dns_zone_name = azurerm_private_dns_zone.web_app_routing[0].name
}
resource "azurerm_role_assignment" "web_app_routing_identity__dns_zone" {
  count = var.enable_web_routing_addon ? 1 : 0

  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = module.aks.web_app_routing_identity[0].object_id
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
    for_each = var.enable_service_endpoints ? [""] : []
    content {
      bypass                     = "AzureServices"
      default_action             = "Deny"
      virtual_network_subnet_ids = [local.aks_nodes_subnet.id]
      ip_rules                   = local.whitelisted_ips
    }
  }

  tags = var.tags
}
resource "azurerm_private_endpoint" "key_vault" {
  count = var.enable_service_endpoints ? 1 : 0

  name                = "${azurerm_key_vault.main.name}-kv"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = local.use_existing_private_endpoints_subnet ? local.private_endpoints_subnet.id : azurerm_subnet.private_endpoints[0].id


  private_service_connection {
    name                           = "${azurerm_key_vault.main.name}-pe"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "privatelink-vaultcore-azure-net"
    private_dns_zone_ids = length(azurerm_private_dns_zone.key_vault) > 0 ? [azurerm_private_dns_zone.key_vault[0].id] : [data.azurerm_private_dns_zone.key_vault[0].id]
  }

  tags = var.tags
}
resource "azurerm_role_assignment" "key_vault_secret_user__aks" {
  scope = azurerm_key_vault.main.id
  principal_id = try(
    module.aks.key_vault_secrets_provider.secret_identity[0].object_id,
    module.aks.cluster_identity.object_id,
  )
  role_definition_name = "Key Vault Secrets User"
}
resource "azurerm_role_assignment" "key_vault_secret_officer__current" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}




# ------ Identity ------ #
resource "azuread_application" "main" {
  count = var.enable_azuread_application ? 1 : 0

  display_name = (
    var.resource_suffix == null ?
    format("%s.nebuly.platform", var.resource_prefix) :
    format("%s.nebuly.platform.%s", var.resource_prefix, var.resource_suffix)
  )
  owners           = [data.azurerm_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg" # default
  identifier_uris  = []
}
resource "azuread_service_principal" "main" {
  count = var.enable_azuread_application ? 1 : 0

  client_id                    = azuread_application.main[0].client_id
  owners                       = [data.azurerm_client_config.current.object_id]
  app_role_assignment_required = true
}
resource "azuread_service_principal_password" "main" {
  count = var.enable_azuread_application ? 1 : 0

  service_principal_id = azuread_service_principal.main[0].id
  end_date_relative    = null
}
resource "azurerm_role_assignment" "nebuly_secrets_officer" {
  count = var.enable_azuread_application ? 1 : 0

  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azuread_service_principal.main[0].object_id
}
resource "azurerm_key_vault_secret" "azuread_application_client_id" {
  count = var.enable_key_vault_secrets ? 1 : 0

  key_vault_id = azurerm_key_vault.main.id
  name         = format("%s-azure-client-id", var.resource_prefix)
  value = (
    length(azuread_application.main) > 0 ?
    azuread_application.main[0].client_id :
    ""
  )

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}
resource "azurerm_key_vault_secret" "azuread_application_client_secret" {
  count        = var.enable_key_vault_secrets ? 1 : 0
  key_vault_id = azurerm_key_vault.main.id
  name         = format("%s-azure-client-secret", var.resource_prefix)
  value = (
    length(azuread_service_principal_password.main) > 0 ?
    azuread_service_principal_password.main[0].value :
    ""
  )

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}



# ------ Nebuly Identity for pulling LLMs ------ # 
resource "azurerm_key_vault_secret" "nebuly_azure_client_id" {
  count = var.enable_key_vault_secrets ? 1 : 0

  key_vault_id = azurerm_key_vault.main.id
  name         = format("%s-nebuly-azure-client-id", var.resource_prefix)
  value        = var.nebuly_credentials.client_id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}
resource "azurerm_key_vault_secret" "nebuly_azure_client_secret" {
  count = var.enable_key_vault_secrets ? 1 : 0

  key_vault_id = azurerm_key_vault.main.id
  name         = format("%s-nebuly-azure-client-secret", var.resource_prefix)
  value        = var.nebuly_credentials.client_secret

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
  private_dns_zone_id = length(azurerm_private_dns_zone.flexible_postgres) > 0 ? azurerm_private_dns_zone.flexible_postgres[0].id : data.azurerm_private_dns_zone.flexible_postgres[0].id

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
  count = var.enable_key_vault_secrets ? 1 : 0

  name         = "${var.resource_prefix}-postgres-username"
  value        = var.postgres_server_admin_username
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}
resource "azurerm_key_vault_secret" "postgres_password" {
  count = var.enable_key_vault_secrets ? 1 : 0

  name         = "${var.resource_prefix}-postgres-password"
  value        = random_password.postgres_server_admin_password.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}




# ------ Azure OpenAI ------ #
locals {
  azure_openai_account_name = (
    var.resource_suffix == null ?
    format("%snebuly", var.resource_prefix) :
    format("%snebuly%s", var.resource_prefix, var.resource_suffix)
  )
}
resource "azurerm_cognitive_account" "main" {
  name                = local.azure_openai_account_name
  location            = var.azure_openai_location
  resource_group_name = data.azurerm_resource_group.main.name
  kind                = "OpenAI"

  sku_name                      = "S0"
  custom_subdomain_name         = local.azure_openai_account_name
  public_network_access_enabled = var.enable_service_endpoints

  dynamic "network_acls" {
    for_each = var.enable_service_endpoints ? [""] : []
    content {
      default_action = "Deny"

      virtual_network_rules {
        subnet_id = local.aks_nodes_subnet.id
      }
    }
  }

  tags = var.tags
}

resource "azurerm_cognitive_deployment" "gpt_4o" {
  count = var.azure_openai_deployment_gpt4o.enabled ? 1 : 0

  cognitive_account_id = azurerm_cognitive_account.main.id
  name                 = "${var.resource_prefix}-gpt-4o"
  rai_policy_name      = var.azure_openai_deployment_gpt4o.rai_policy_name

  model {
    format  = "OpenAI"
    name    = var.azure_openai_deployment_gpt4o.name
    version = var.azure_openai_deployment_gpt4o.version
  }
  scale {
    type     = "Standard"
    capacity = var.azure_openai_deployment_gpt4o.rate_limit
  }
}
resource "azurerm_cognitive_deployment" "gpt_4o_mini" {
  count = var.azure_openai_deployment_gpt4o_mini.enabled ? 1 : 0

  cognitive_account_id = azurerm_cognitive_account.main.id
  name                 = "${var.resource_prefix}-gpt-4o-mini"
  rai_policy_name      = var.azure_openai_deployment_gpt4o_mini.rai_policy_name

  model {
    format  = "OpenAI"
    name    = var.azure_openai_deployment_gpt4o_mini.name
    version = var.azure_openai_deployment_gpt4o_mini.version
  }
  scale {
    type     = "Standard"
    capacity = var.azure_openai_deployment_gpt4o_mini.rate_limit
  }
}
resource "azurerm_key_vault_secret" "azure_openai_api_key" {
  count = var.enable_key_vault_secrets ? 1 : 0

  name         = "${var.resource_prefix}-openai-api-key"
  value        = azurerm_cognitive_account.main.primary_access_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}
resource "azurerm_private_endpoint" "openai" {
  name                = "${azurerm_cognitive_account.main.name}-openai"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = local.use_existing_private_endpoints_subnet ? local.private_endpoints_subnet.id : azurerm_subnet.private_endpoints[0].id

  private_service_connection {
    name                           = azurerm_cognitive_account.main.name
    private_connection_resource_id = azurerm_cognitive_account.main.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  private_dns_zone_group {
    name                 = "privatelink-openai"
    private_dns_zone_ids = length(azurerm_private_dns_zone.openai) > 0 ? [azurerm_private_dns_zone.openai[0].id] : [data.azurerm_private_dns_zone.openai[0].id]
  }

  tags = var.tags
}




# ------ Model Registry ------ #
locals {
  storage_account_generated_name = (
    var.resource_suffix == null ?
    format("%smodels", var.resource_prefix) :
    format("%smodels%s", var.resource_prefix, var.resource_suffix)

  )
  storage_account_name = (
    var.storage_account_override_name == null ?
    local.storage_account_generated_name :
    var.storage_account_override_name
  )
}
resource "azurerm_storage_account" "main" {
  name                = local.storage_account_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  public_network_access_enabled = var.enable_service_endpoints
  is_hns_enabled                = false

  dynamic "network_rules" {
    for_each = var.enable_service_endpoints ? [""] : []
    content {
      default_action             = "Deny"
      ip_rules                   = local.whitelisted_ips
      virtual_network_subnet_ids = [local.aks_nodes_subnet.id]
    }
  }

  tags = var.tags
}
resource "azurerm_storage_container" "models" {
  count = var.enable_storage_containers ? 1 : 0

  storage_account_name = azurerm_storage_account.main.name
  name                 = "models"
}
resource "azurerm_role_assignment" "storage_container_models__data_contributor" {
  count = var.enable_storage_containers ? 1 : 0

  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.aks.kubelet_identity[0].object_id
  scope                = azurerm_storage_container.models[0].resource_manager_id
}
resource "azurerm_private_endpoint" "models_blob" {
  name                = "${azurerm_storage_account.main.name}-blob"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = local.use_existing_private_endpoints_subnet ? local.private_endpoints_subnet.id : azurerm_subnet.private_endpoints[0].id


  private_service_connection {
    name                           = "${azurerm_storage_account.main.name}-blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "privatelink-blob-core-windows-net"
    private_dns_zone_ids = length(azurerm_private_dns_zone.blob) > 0 ? [azurerm_private_dns_zone.blob[0].id] : [data.azurerm_private_dns_zone.blob[0].id]
  }

  tags = var.tags
}
resource "azurerm_private_endpoint" "models_dfs" {
  name                = "${azurerm_storage_account.main.name}-dfs"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = local.use_existing_private_endpoints_subnet ? local.private_endpoints_subnet.id : azurerm_subnet.private_endpoints[0].id


  private_service_connection {
    name                           = "${azurerm_storage_account.main.name}-dfs"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["dfs"]
  }

  private_dns_zone_group {
    name                 = "privatelink-blob-core-windows-net"
    private_dns_zone_ids = length(azurerm_private_dns_zone.dfs) > 0 ? [azurerm_private_dns_zone.dfs[0].id] : [data.azurerm_private_dns_zone.dfs[0].id]
  }

  tags = var.tags
}


# ------ Backups Storage ------ #
locals {
  backups_storage_account_generated_name = (
    var.resource_suffix == null ?
    format("%sbackups", var.resource_prefix) :
    format("%sbackups%s", var.resource_prefix, var.resource_suffix)

  )
  backups_storage_account_name = local.backups_storage_account_generated_name
}
resource "azurerm_storage_account" "backups" {
  name                = local.backups_storage_account_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = var.backups_storage_replication_type
  access_tier              = "Hot"

  public_network_access_enabled = false
  is_hns_enabled                = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.backups_storage_delete_retention_days
    }
  }
  tags = var.tags
}
#resource "azurerm_storage_container" "clickhouse" {
#  storage_account_name = azurerm_storage_account.backups.name
#  name                 = "clickhouse"
#}
resource "azurerm_private_endpoint" "backups_blob" {
  name                = "${azurerm_storage_account.backups.name}-blob"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = local.use_existing_private_endpoints_subnet ? local.private_endpoints_subnet.id : azurerm_subnet.private_endpoints[0].id


  private_service_connection {
    name                           = "${azurerm_storage_account.backups.name}-blob"
    private_connection_resource_id = azurerm_storage_account.backups.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "privatelink-blob-core-windows-net"
    private_dns_zone_ids = length(azurerm_private_dns_zone.blob) > 0 ? [azurerm_private_dns_zone.blob[0].id] : [data.azurerm_private_dns_zone.blob[0].id]
  }

  tags = var.tags
}
resource "azurerm_private_endpoint" "backups_dfs" {
  name                = "${azurerm_storage_account.backups.name}-dfs"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = local.use_existing_private_endpoints_subnet ? local.private_endpoints_subnet.id : azurerm_subnet.private_endpoints[0].id


  private_service_connection {
    name                           = "${azurerm_storage_account.backups.name}-dfs"
    private_connection_resource_id = azurerm_storage_account.backups.id
    is_manual_connection           = false
    subresource_names              = ["dfs"]
  }

  private_dns_zone_group {
    name                 = "privatelink-blob-core-windows-net"
    private_dns_zone_ids = length(azurerm_private_dns_zone.dfs) > 0 ? [azurerm_private_dns_zone.dfs[0].id] : [data.azurerm_private_dns_zone.dfs[0].id]
  }

  tags = var.tags
}
resource "azurerm_storage_management_policy" "backups" {
  storage_account_id = azurerm_storage_account.backups.id

  rule {
    enabled = true
    name    = "delete-previous-versions"

    filters {
      prefix_match = []
      blob_types   = ["blockBlob", "appendBlob"]
    }

    actions {
      version {
        delete_after_days_since_creation = var.backups_storage_delete_retention_days
      }
    }
  }

  rule {
    enabled = true
    name    = "move-to-cool"

    filters {
      prefix_match = []
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_creation_greater_than = var.backups_storage_tier_to_cool_after_days_since_creation_greater_than
      }
    }
  }
}
#resource "azurerm_key_vault_secret" "backups_storage_primary_key" {
#  name         = "${var.resource_prefix}-backups-storage-primary-key"
#  value        = azurerm_storage_account.backups.primary_access_key
#  key_vault_id = azurerm_key_vault.main.id
#
#  depends_on = [
#    azurerm_role_assignment.key_vault_secret_officer__current
#  ]
#}




# ------ AKS ------ #
resource "tls_private_key" "aks" {
  algorithm = "RSA" # Azure VMs currently do not support ECDSA
  rsa_bits  = "4096"
}
resource "azuread_group" "aks_admins" {
  count = var.enable_azuread_groups ? 1 : 0

  display_name = (
    var.resource_suffix == null ?
    "${var.resource_prefix}.nebuly.aks-admins" :
    "${var.resource_prefix}-nebuly.aks-admins.${var.resource_suffix}"
  )
  security_enabled = true
}
resource "azuread_group_member" "aks_admin_users" {
  for_each = var.enable_azuread_groups ? data.azuread_user.aks_admins : {}

  group_object_id  = azuread_group.aks_admins[0].id
  member_object_id = each.value.object_id
}
module "aks" {
  source  = "Azure/aks/azurerm"
  version = "9.4.1"

  prefix              = var.resource_prefix
  cluster_name        = local.aks_cluster_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name

  kubernetes_version   = var.aks_kubernetes_version.control_plane
  orchestrator_version = var.aks_kubernetes_version.workers
  sku_tier             = var.aks_sku_tier

  vnet_subnet_id             = local.aks_nodes_subnet.id
  net_profile_service_cidr   = var.aks_net_profile_service_cidr
  net_profile_dns_service_ip = var.aks_net_profile_dns_service_ip

  private_cluster_enabled         = var.aks_private_cluster_enabled
  private_dns_zone_id             = var.aks_private_cluster_enabled ? "System" : null
  api_server_authorized_ip_ranges = var.aks_private_cluster_enabled ? null : local.whitelisted_ips

  rbac_aad_admin_group_object_ids = var.enable_azuread_groups ? setunion(
    var.aks_cluster_admin_group_object_ids,
    [azuread_group.aks_admins[0].id],
  ) : var.aks_cluster_admin_group_object_ids
  rbac_aad_managed                  = true
  role_based_access_control_enabled = true
  local_account_disabled            = true

  log_analytics_workspace         = var.aks_log_analytics_workspace
  log_analytics_workspace_enabled = var.aks_log_analytics_workspace_enabled
  log_analytics_solution          = var.aks_log_analytics_solution

  temporary_name_for_rotation = "systemback"

  web_app_routing = length(azurerm_private_dns_zone.web_app_routing) > 0 ? {
    dns_zone_id = azurerm_private_dns_zone.web_app_routing[0].id
  } : null

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

  network_policy      = "azure"
  network_plugin      = "azure"
  network_plugin_mode = var.aks_network_plugin_mode

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
  count = var.enable_key_vault_secrets ? 1 : 0

  key_vault_id = azurerm_key_vault.main.id
  name         = format("%s-jwt-signing-key", var.resource_prefix)
  value        = tls_private_key.jwt_signing_key.private_key_pem

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}


# ------ External Secrets ------ #
resource "azurerm_key_vault_secret" "okta_sso_client_id" {
  count = (var.okta_sso != null && var.enable_key_vault_secrets) ? 1 : 0

  name         = "${var.resource_prefix}-okta-sso-client-id"
  value        = var.okta_sso.client_id
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}
resource "azurerm_key_vault_secret" "okta_sso_client_secret" {
  count = var.okta_sso == null ? 0 : 1

  name         = "${var.resource_prefix}-okta-sso-client-secret"
  value        = var.okta_sso.client_secret
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}
resource "azurerm_key_vault_secret" "google_sso_client_id" {
  count = (var.google_sso != null && var.enable_key_vault_secrets) ? 1 : 0

  name         = "${var.resource_prefix}-google-sso-client-id"
  value        = var.google_sso.client_id
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}
resource "azurerm_key_vault_secret" "google_sso_client_secret" {
  count = var.google_sso == null ? 0 : 1

  name         = "${var.resource_prefix}-google-sso-client-secret"
  value        = var.okta_sso.client_secret
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.key_vault_secret_officer__current
  ]
}


# ------ Post provisioning ------ #
locals {
  missing_value_placeholder         = "TODO"
  secret_provider_class_name        = "nebuly-platform"
  secret_provider_class_secret_name = "nebuly-platform-credentials"

  # k8s secrets keys
  k8s_secret_key_db_username          = "db-username"
  k8s_secret_key_db_password          = "db-password"
  k8s_secret_key_jwt_signing_key      = "jwt-signing-key"
  k8s_secret_key_openai_api_key       = "openai-api-key"
  k8s_secret_key_azure_client_id      = "azure-client-id"
  k8s_secret_key_azure_client_secret  = "azure-client-secret"
  k8s_secret_key_nebuly_client_id     = "nebuly-azure-client-id"
  k8s_secret_key_nebuly_client_secret = "nebuly-azure-client-secret"

  k8s_secret_key_okta_sso_client_id       = "okta-sso-client-id"
  k8s_secret_key_okta_sso_client_secret   = "okta-sso-client-secret"
  k8s_secret_key_google_sso_client_id     = "google-sso-client-id"
  k8s_secret_key_google_sso_client_secret = "google-sso-client-secret"

  helm_values = templatefile(
    "${path.module}/templates/helm-values.tpl.yaml",
    {
      platform_domain        = var.platform_domain
      image_pull_secret_name = var.k8s_image_pull_secret_name

      openai_endpoint               = azurerm_cognitive_account.main.endpoint
      openai_gpt4o_deployment       = try(azurerm_cognitive_deployment.gpt_4o[0].name, "\"\"")
      openai_translation_deployment = try(azurerm_cognitive_deployment.gpt_4o_mini[0].name, "\"\"")

      secret_provider_class_name        = local.secret_provider_class_name
      secret_provider_class_secret_name = local.secret_provider_class_secret_name

      k8s_secret_key_db_username          = local.k8s_secret_key_db_username
      k8s_secret_key_db_password          = local.k8s_secret_key_db_password
      k8s_secret_key_jwt_signing_key      = local.k8s_secret_key_jwt_signing_key
      k8s_secret_key_openai_api_key       = local.k8s_secret_key_openai_api_key
      k8s_secret_key_nebuly_client_secret = local.k8s_secret_key_nebuly_client_secret
      k8s_secret_key_nebuly_client_id     = local.k8s_secret_key_nebuly_client_id

      postgres_server_url              = azurerm_postgresql_flexible_server.main.fqdn
      postgres_auth_database_name      = azurerm_postgresql_flexible_server_database.auth.name
      postgres_analytics_database_name = azurerm_postgresql_flexible_server_database.analytics.name

      okta_sso_enabled        = var.okta_sso != null
      okta_sso_issuer         = var.okta_sso != null ? var.okta_sso.issuer : ""
      google_sso_enabled      = var.google_sso != null
      google_sso_issuer       = var.google_sso != null ? var.google_sso.issuer : ""
      google_sso_role_mapping = var.google_sso != null ? join(",", [for role, group in var.google_sso.role_mapping : "${role}:${group}"]) : ""

      k8s_secret_key_okta_sso_client_id       = local.k8s_secret_key_okta_sso_client_id
      k8s_secret_key_okta_sso_client_secret   = local.k8s_secret_key_okta_sso_client_secret
      k8s_secret_key_google_sso_client_id     = local.k8s_secret_key_google_sso_client_id
      k8s_secret_key_google_sso_client_secret = local.k8s_secret_key_google_sso_client_secret

      kubelet_identity_client_id = module.aks.kubelet_identity[0].client_id
      storage_account_name       = azurerm_storage_account.main.name
      storage_container_name     = try(azurerm_storage_container.models[0].name, "")
      tenant_id                  = data.azurerm_client_config.current.tenant_id

      ingress_class_name = (
        var.enable_web_routing_addon ?
        "webapprouting.kubernetes.azure.com" :
        "nginx"
      )
    },
  )
  helm_values_bootstrap = templatefile(
    "${path.module}/templates/helm-values-bootstrap.tpl.yaml",
    {
      aks_cluster_name = local.aks_cluster_name
    }
  )
  secret_provider_class = templatefile(
    "${path.module}/templates/secret-provider-class.tpl.yaml",
    {
      secret_provider_class_name        = local.secret_provider_class_name
      secret_provider_class_secret_name = local.secret_provider_class_secret_name
      okta_sso_enabled                  = var.okta_sso != null

      key_vault_name          = azurerm_key_vault.main.name
      tenant_id               = data.azurerm_client_config.current.tenant_id
      aks_managed_identity_id = try(module.aks.key_vault_secrets_provider.secret_identity[0].client_id, "TODO")

      secret_name_jwt_signing_key        = try(azurerm_key_vault_secret.jwt_signing_key[0].name, local.missing_value_placeholder)
      secret_name_db_username            = try(azurerm_key_vault_secret.postgres_user[0].name, local.missing_value_placeholder)
      secret_name_db_password            = try(azurerm_key_vault_secret.postgres_password[0].name, local.missing_value_placeholder)
      secret_name_openai_api_key         = try(azurerm_key_vault_secret.azure_openai_api_key[0].name, local.missing_value_placeholder)
      secret_name_azure_client_id        = try(azurerm_key_vault_secret.azuread_application_client_id[0].name, local.missing_value_placeholder)
      secret_name_azure_client_secret    = try(azurerm_key_vault_secret.azuread_application_client_secret[0].name, local.missing_value_placeholder)
      secret_name_nebuly_client_id       = try(azurerm_key_vault_secret.nebuly_azure_client_id[0].name, local.missing_value_placeholder)
      secret_name_nebuly_client_secret   = try(azurerm_key_vault_secret.nebuly_azure_client_secret[0].name, local.missing_value_placeholder)
      secret_name_okta_sso_client_id     = var.okta_sso == null ? "" : azurerm_key_vault_secret.okta_sso_client_id[0].name
      secret_name_okta_sso_client_secret = var.okta_sso == null ? "" : azurerm_key_vault_secret.okta_sso_client_secret[0].name


      k8s_secret_key_db_username            = local.k8s_secret_key_db_username
      k8s_secret_key_db_password            = local.k8s_secret_key_db_password
      k8s_secret_key_jwt_signing_key        = local.k8s_secret_key_jwt_signing_key
      k8s_secret_key_openai_api_key         = local.k8s_secret_key_openai_api_key
      k8s_secret_key_azure_client_id        = local.k8s_secret_key_azure_client_id
      k8s_secret_key_azure_client_secret    = local.k8s_secret_key_azure_client_secret
      k8s_secret_key_nebuly_client_secret   = local.k8s_secret_key_nebuly_client_secret
      k8s_secret_key_nebuly_client_id       = local.k8s_secret_key_nebuly_client_id
      k8s_secret_key_okta_sso_client_id     = local.k8s_secret_key_okta_sso_client_id
      k8s_secret_key_okta_sso_client_secret = local.k8s_secret_key_okta_sso_client_secret
    },
  )
}

