# ------- General ------ #
variable "resource_prefix" {
  type        = string
  description = "The prefix that is used for generating resource names."
}
variable "resource_suffix" {
  type        = string
  description = "The suffix that is used for generating resource names."
  default     = null
}
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags that are applied to all resources."
}
variable "location" {
  type        = string
  description = "The region where to provision the resources."
}
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where to provision the resources."
}
variable "platform_domain" {
  type        = string
  description = "The domain on which the deployed Nebuly platform is made accessible."
  validation {
    condition     = can(regex("(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]", var.platform_domain))
    error_message = "The domain name must be a valid domain (e.g., example.com)."
  }
}

variable "nebuly_credentials" {
  type = object({
    client_id : string
    client_secret : string
  })
  description = <<EOT
  The credentials provided by Nebuly are required for activating your platform installation. 
  If you haven't received your credentials or have lost them, please contact support@nebuly.ai.
  EOT
}


# ------ Kubernetes ------ #
variable "k8s_image_pull_secret_name" {
  default     = "nebuly-docker-pull"
  description = <<EOT
  The name of the Kubernetes Image Pull Secret to use. 
  This value will be used to auto-generate the values.yaml file for installing the Nebuly Platform Helm chart.
  EOT
  type        = string
}


# ------ PostgreSQL Databases ------ #
variable "postgres_server_sku" {
  type = object({
    tier : string
    name : string
  })
  default = {
    # General purpose - 4 cores, 16GB
    tier = "GP"
    name = "Standard_D4ds_v5"
  }
  description = "The SKU of the PostgreSQL Server, including the Tier and the Name. Examples: B_Standard_B1ms, GP_Standard_D2s_v3, MO_Standard_E4s_v3"
}
variable "postgres_server_admin_username" {
  type        = string
  default     = "nebulyadmin"
  description = "The username of the admin user of the PostgreSQL Server."
}
variable "postgres_server_max_storage_mb" {
  type        = number
  description = "The max storage allowed for the PostgreSQL Flexible Server. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216 and 33553408."
  default     = 262144
}
variable "postgres_server_high_availability" {
  description = "High-availability configuration of the DB server. Possible values for mode are: SameZone or ZoneRedundant."
  type = object({
    enabled : bool
    mode : optional(string, "SameZone")
    standby_availability_zone : optional(string, null)
  })
  default = {
    enabled = true
    mode    = "SameZone"
  }
}
variable "postgres_override_name" {
  type        = string
  default     = null
  description = "Override the name of the PostgreSQL Server. If not provided, the name is generated based on the resource_prefix."
}
variable "postgres_server_maintenance_window" {
  type = object({
    day_of_week : number
    start_hour : number
    start_minute : number
  })
  default = {
    day_of_week  = 0
    start_hour   = 0
    start_minute = 0
  }
  description = "The window for performing automatic maintenance of the PostgreSQL Server. Default is Sunday at 00:00 of the timezone of the server location."
}
variable "postgres_server_point_in_time_backup" {
  type = object({
    geo_redundant : optional(bool, true)
    retention_days : optional(number, 30)
  })
  default = {
    geo_redundant  = true
    retention_days = 30
  }
  description = "The backup settings of the PostgreSQL Server."
}
variable "postgres_server_optional_configurations" {
  type        = map(string)
  description = "Optional Flexible PostgreSQL configurations. Defaults to recommended configurations."
  default = {
    # PGAudit Settings
    "pgaudit.log" : "WRITE",
    # Query performance settings
    "pg_qs.query_capture_mode" : "ALL",
    "pg_qs.retention_period_in_days" : "7",
    "pg_qs.store_query_plans" : "on",
    "pgms_wait_sampling.query_capture_mode" : "ALL",
    "track_io_timing" : "on",
    # Performance tuning
    "intelligent_tuning" : "on",
    "intelligent_tuning.metric_targets" : "ALL",
    # Enhanced metrics
    "metrics.collector_database_activity" : "on",
    "metrics.autovacuum_diagnostics" : "on",
  }
}
variable "postgres_server_lock" {
  type = object({
    enabled = optional(bool, false)
    notes   = optional(string, "Cannot be deleted.")
    name    = optional(string, "terraform-lock")
  })
  default = {
    enabled = true
  }
  description = "Optionally lock the PostgreSQL server to prevent deletion."
}
variable "postgres_server_alert_rules" {
  description = "The Azure Monitor alert rules to set on the provisioned PostgreSQL server."
  type = map(object({
    description     = string
    frequency       = string
    window_size     = string
    action_group_id = string
    severity        = number

    criteria = optional(
      object({
        aggregation = string
        metric_name = string
        operator    = string
        threshold   = number
      })
    , null)
    dynamic_criteria = optional(
      object({
        aggregation       = string
        metric_name       = string
        operator          = string
        alert_sensitivity = string
      })
    , null)
  }))
  default = {}
}
variable "postgres_version" {
  type        = string
  default     = "16"
  description = "The PostgreSQL version to use."
}


# ------ Key Vault ------ #
variable "key_vault_override_name" {
  type        = string
  default     = null
  description = "Override the name of the Key Vault. If not provided, the name is generated based on the resource_prefix."
}
variable "key_vault_sku_name" {
  type        = string
  default     = "Standard"
  description = "The SKU of the Key Vault."
}
variable "key_vault_public_network_access_enabled" {
  type        = bool
  default     = true
  description = <<EOT
  Can the Key Vault be accessed from the Internet, according to the firewall rules?
  Default to true to to allow the Terraform module to be executed even outside the private virtual network. 
  When set to true, firewall rules are applied, and all connections are denied by default.
  EOT
}
variable "key_vault_soft_delete_retention_days" {
  type        = number
  default     = 7
  description = "The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days."
}
variable "key_vault_purge_protection_enabled" {
  type        = bool
  default     = false
  description = "Is purge protection enabled for the Key Vault?"
}


# ------ Storage Account ------ #
variable "storage_account_override_name" {
  type        = string
  default     = null
  description = "Override the name of the Storage Account. If not provided, the name is generated based on the resource_prefix."
}


# ------ Networking ------ #
variable "whitelisted_ips" {
  description = <<EOT
  Optional list of IPs or IP Ranges that will be able to access the following resources from the internet: Azure Kubernetes Service (AKS) API Server, 
  Azure Key Vault, Azure Storage Account. If 0.0.0.0/0 (default value), no whitelisting is enforced and the resources are accessible from all IPs.

  The whitelisting excludes the Database Server, which remains unexposed to the Internet and is accessible only from the virtual network.
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
variable "virtual_network" {
  description = <<EOT
  Optional name of the virtual network in which to create the resources. 
  If not provided, a new virtual network is created.
  EOT
  type = object({
    name                = string
    resource_group_name = string
  })
  default = null
}
variable "virtual_network_address_space" {
  description = <<EOT
  Address space of the new virtual network in which to create resources. 
  If `virtual_network_name` is provided, the existing virtual network is used and this variable is ignored.
  EOT
  type        = list(string)
  default     = ["10.0.0.0/16"]
}
variable "subnet_name_aks_nodes" {
  description = <<EOT
  Optional name of the subnet to be used for provisioning AKS nodes.
  If not provided, a new subnet is created.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.virtual_network != null || var.subnet_name_aks_nodes == null
    error_message = "`virtual_network` cannot be null when specifying existing subnet name."
  }
}
variable "subnet_address_space_aks_nodes" {
  description = <<EOT
  Address space of the new subnet in which to create the nodes of the AKS cluster. 
  If `subnet_name_aks_nodes` is provided, the existing subnet is used and this variable is ignored.
  EOT
  type        = list(string)
  default     = ["10.0.0.0/22"]
}
variable "subnet_name_private_endpoints" {
  description = <<EOT
  Optional name of the subnet to which attach the Private Endpoints. 
  If not provided, a new subnet is created.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.virtual_network != null || var.subnet_name_private_endpoints == null
    error_message = "`virtual_network` cannot be null when specifying existing subnet name."
  }
}
variable "subnet_address_space_private_endpoints" {
  description = <<EOT
  Address space of the new subnet in which to create private endpoints. 
  If `subnet_name_private_endpoints` is provided, the existing subnet is used and this variable is ignored.
  EOT
  type        = list(string)
  default     = ["10.0.8.0/26"]
}
variable "subnet_name_flexible_postgres" {
  description = <<EOT
  Optional name of the subnet delegated to Flexible PostgreSQL Server service. 
  If not provided, a new subnet is created.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.virtual_network != null || var.subnet_name_flexible_postgres == null
    error_message = "`virtual_network` cannot be null when specifying existing subnet name."
  }
}
variable "subnet_address_space_flexible_postgres" {
  description = <<EOT
  Address space of the new subnet delgated to Flexible PostgreSQL Server service. 
  If `subnet_name_flexible_postgres` is provided, the existing subnet is used and this variable is ignored.
  EOT
  type        = list(string)
  default     = ["10.0.12.0/26"]
}
variable "private_dns_zones" {
  description = <<EOT
  Private DNS zones to use for Private Endpoint connections. If not provided, a new DNS Zone 
  is created and linked to the respective subnet.
  EOT
  type = object({
    flexible_postgres = optional(object({
      name : string
      resource_group_name : string
    }), null)
    key_vault = optional(object({
      name : string
      resource_group_name : string
    }), null)
    blob = optional(object({
      name : string
      resource_group_name : string
    }), null)
    dfs = optional(object({
      name : string
      resource_group_name : string
    }), null)
  })
  default = {}
}


# ------ External Credentials ------ #
variable "okta_sso" {
  description = "Settings for configuring the Okta SSO integration."
  type = object({
    issuer : string
    client_id : string
    client_secret : string
  })
  default = null
}


# ------ Azure OpenAI ------ #
variable "azure_openai_deployment_gpt4o" {
  description = ""
  type = object({
    name : optional(string, "gpt-4o")
    version : optional(string, "2024-08-06")
    rate_limit : optional(number, 80)
    rai_policy_name : optional(string, "Microsoft.Default")
    enabled : optional(bool, true)
  })
  default = {}
}
variable "azure_openai_deployment_gpt4o_mini" {
  description = ""
  type = object({
    name : optional(string, "gpt-4o-mini")
    version : optional(string, "2024-07-18")
    rate_limit : optional(number, 80)
    rai_policy_name : optional(string, "Microsoft.Default")
    enabled : optional(bool, true)
  })
  default = {}
}
variable "azure_openai_location" {
  description = <<EOT
  The Azure region where to deploy the Azure OpenAI models. 
  Note that the models required by Nebuly are supported only in few specific regions. For more information, you can refer to Azure documentation:
  https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#standard-deployment-model-availability
  EOT
  type        = string
  default     = "EastUS"

  validation {
    condition     = contains(["EastUS", "FranceCentral", "SwedenCentral"], var.azure_openai_location)
    error_message = "Region not supported."
  }
}


# ------ AKS ------ #
variable "aks_override_name" {
  type        = string
  description = "Override the name of the Azure Kubernetes Service resource. If not provided, the name is generated based on the resource_prefix."
  default     = null
}
variable "aks_kubernetes_version" {
  description = "The Kubernetes version to use."
  default = {
    workers       = "1.31.3"
    control_plane = "1.31.3"
  }
  type = object({
    workers       = string
    control_plane = string
  })
}
variable "aks_sku_tier" {
  description = "The AKS tier. Possible values are: Free, Standard, Premium. It is recommended to use Standard or Premium for production workloads."
  default     = "Standard"
  type        = string
}
variable "aks_net_profile_service_cidr" {
  type        = string
  description = "The Network Range used by the Kubernetes service. Must not overlap with the AKS Nodes address space. Example: 10.32.0.0/24"
  default     = "10.32.0.0/24"
}
variable "aks_net_profile_dns_service_ip" {
  type        = string
  description = " IP address within the Kubernetes service address range that is used by cluster service discovery (kube-dns). Must be inluced in net_profile_cidr. Example: 10.32.0.10"
  default     = "10.32.0.10"
}
variable "aks_log_analytics_workspace_enabled" {
  description = "Enable the integration of azurerm_log_analytics_workspace and azurerm_log_analytics_solution."
  type        = bool
  default     = true
}
variable "aks_log_analytics_workspace" {
  description = "Existing azurerm_log_analytics_workspace to attach azurerm_log_analytics_solution. Providing the config disables creation of azurerm_log_analytics_workspace."
  type = object({
    id                  = string
    name                = string
    location            = optional(string)
    resource_group_name = optional(string)
  })
  default = null
}
variable "aks_log_analytics_solution" {
  description = "Existing azurerm_log_analytics_solution to be attached to the azurerm_log_analytics_workspace. Providing the config disables creation of azurerm_log_analytics_solution."
  type = object({
    id                  = string
    name                = string
    location            = optional(string)
    resource_group_name = optional(string)
  })
  default = null
}
variable "aks_cluster_admin_users" {
  description = "User Principal Names (UPNs) of the users that are granted the Cluster Admin role over the AKS cluster."
  type        = set(string)
}
variable "aks_cluster_admin_group_object_ids" {
  description = "Object IDs that are granted the Cluster Admin role over the AKS cluster."
  type        = set(string)
}
variable "aks_sys_pool" {
  description = "The configuration of the AKS System Nodes Pool."
  type = object({
    vm_size : string
    nodes_max_pods : number
    name : string
    availability_zones : list(string)
    disk_size_gb : number
    disk_type : string
    nodes_labels : optional(map(string), {})
    nodes_tags : optional(map(string), {})
    only_critical_addons_enabled : optional(bool, false)
    # Auto-scaling settings
    nodes_count : optional(number, null)
    enable_auto_scaling : optional(bool, false)
    agents_min_count : optional(number, null)
    agents_max_count : optional(number, null)
  })
  default = {
    vm_size                      = "Standard_E4ads_v5" # 4 CPU, 32 GB memory
    name                         = "system"
    disk_size_gb                 = 128
    disk_type                    = "Ephemeral"
    availability_zones           = ["1", "2", "3"]
    nodes_max_pods               = 60
    only_critical_addons_enabled = false
    # Auto-scaling setttings
    enable_auto_scaling = true
    agents_min_count    = 1
    agents_max_count    = 1
  }
}
variable "aks_worker_pools" {
  description = <<EOT
  The worker pools of the AKS cluster, each with the respective configuration.
  The default configuration uses a single worker node, with no HA.
  EOT
  type = map(object({
    enabled : optional(bool, true)
    vm_size : string
    priority : optional(string, "Regular")
    tags : map(string)
    max_pods : number
    disk_size_gb : optional(number, 128)
    disk_type : string
    availability_zones : list(string)
    node_taints : optional(list(string), [])
    node_labels : optional(map(string), {})
    # Auto-scaling settings
    nodes_count : optional(number, null)
    enable_auto_scaling : optional(bool, false)
    nodes_min_count : optional(number, null)
    nodes_max_count : optional(number, null)
  }))
  default = {
    "a100wr" : {
      vm_size  = "Standard_NC24ads_A100_v4"
      priority = "Regular"
      max_pods : 30
      disk_size_gb = 128
      disk_type : "Ephemeral"
      availability_zones = ["1", "2", "3"]
      tags : {}
      node_taints : [
        "nvidia.com/gpu=:NoSchedule",
      ]
      node_labels : {
        "nebuly.com/accelerator" : "nvidia-ampere-a100"
      }
      # Auto-scaling setttings
      enable_auto_scaling = true
      nodes_count : null
      nodes_min_count = 0
      nodes_max_count = 1
    }
    "t4workers" : {
      vm_size  = "Standard_NC4as_T4_v3"
      priority = "Regular"
      max_pods : 30
      disk_size_gb = 128
      disk_type : "Ephemeral"
      availability_zones = ["1", "2", "3"]
      node_taints : [
        "nvidia.com/gpu=:NoSchedule",
      ]
      node_labels : {
        "nebuly.com/accelerator" : "nvidia-tesla-t4"
      }
      # Auto-scaling setttings
      enable_auto_scaling = true
      nodes_count : null
      nodes_min_count = 0
      nodes_max_count = 1
      # Tags
      tags : {}
    }
  }
}


# ------ Backups ------ #
variable "backups_storage_replication_type" {
  description = "The replication type of the backups storage account. Possible values are: LRS, GRS, RAGRS, ZRS."
  type        = string
  default     = "GRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.backups_storage_replication_type)
    error_message = "Invalid replication type."
  }
}
variable "backups_storage_delete_retention_days" {
  description = "The number of days that backups should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days."
  type        = number
  default     = 7
  validation {
    condition     = var.backups_storage_delete_retention_days >= 7 && var.backups_storage_delete_retention_days <= 90
    error_message = "The value must be between 7 and 90 days."
  }
}
variable "backups_storage_tier_to_cool_after_days_since_creation_greater_than" {
  description = "The number of days after which to move the backups to the Cool tier."
  type        = number
  default     = 7
}
