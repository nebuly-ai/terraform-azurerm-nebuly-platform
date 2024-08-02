# ------- General ------ #
variable "resource_prefix" {
  type        = string
  description = "The prefix that will be used for generating resource names."
}
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags that will be applied to all resources."
}
variable "location" {
  type        = string
  description = "The region where to provision the resources."
}
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where to provision the resources."
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
    mode : string
    standby_availability_zone : optional(string, null)
  })
  default = {
    enabled = true
    mode    = "SameZone"
  }
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
variable "postgres_server_networking" {
  description = <<EOF
  Server networking configuration. 

  If allowed_ip_ranges is not empty, then the server is accessible from 
  the Internet through the configured firewall rules.

  If delegated_subnet_id or private_dns_zone_id are provided, then the Server 
  is accessible only from the specified virutal network.
  
  EOF
  type = object({
    allowed_ip_ranges : optional(list(object({
      name : string
      start_ip_address : string
      end_ip_address : string
    })), [])
    delegated_subnet_id : optional(string, null)
    private_dns_zone_id : optional(string, null)
    public_network_access_enabled : optional(bool, false)
  })
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



# ------ External credentials ------ #
variable "openai_api_key" {
  description = "The API Key used for authenticating with OpenAI."
  type        = string
}

