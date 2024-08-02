# Nebuly Platform (Azure)

Terraform module for provisioning Nebuly Platform resources on Microsoft Azure.

Available on [Terraform Registry](https://registry.terraform.io/modules/nebuly-ai/nebuly-platform/azurerm/latest).

## Examples

### Basic usage
```hcl

```





## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.114.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.2 |


## Outputs

No outputs.


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_key_vault_network_acls"></a> [key\_vault\_network\_acls](#input\_key\_vault\_network\_acls) | Optional configuration of network ACLs. | <pre>object({<br>    bypass : string<br>    default_action : string<br>    ip_rules : list(string)<br>    virtual_network_subnet_ids : list(string)<br>  })</pre> | `null` | no |
| <a name="input_key_vault_private_dns_zone"></a> [key\_vault\_private\_dns\_zone](#input\_key\_vault\_private\_dns\_zone) | Optional Private DNS Zone to link with the Key Vault when private endpoint integration is enabled. | <pre>object({<br>    id : string<br>    name : string<br>  })</pre> | `null` | no |
| <a name="input_key_vault_private_endpoints"></a> [key\_vault\_private\_endpoints](#input\_key\_vault\_private\_endpoints) | Optional Private Endpoints to link with the Key Vault. | <pre>map(object({<br>    subnet_id = string<br>    vnet_id   = string<br>  }))</pre> | `{}` | no |
| <a name="input_key_vault_public_network_access_enabled"></a> [key\_vault\_public\_network\_access\_enabled](#input\_key\_vault\_public\_network\_access\_enabled) | Can the Key Vault be accessed from the Internet? | `bool` | n/a | yes |
| <a name="input_key_vault_purge_protection_enabled"></a> [key\_vault\_purge\_protection\_enabled](#input\_key\_vault\_purge\_protection\_enabled) | Is purge protection enabled for the Key Vault? | `bool` | `false` | no |
| <a name="input_key_vault_sku_name"></a> [key\_vault\_sku\_name](#input\_key\_vault\_sku\_name) | The SKU of the Key Vault. | `string` | `"Standard"` | no |
| <a name="input_key_vault_soft_delete_retention_days"></a> [key\_vault\_soft\_delete\_retention\_days](#input\_key\_vault\_soft\_delete\_retention\_days) | The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days. | `number` | `7` | no |
| <a name="input_location"></a> [location](#input\_location) | The region where to provision the resources. | `string` | n/a | yes |
| <a name="input_openai_api_key"></a> [openai\_api\_key](#input\_openai\_api\_key) | The API Key used for authenticating with OpenAI. | `string` | n/a | yes |
| <a name="input_postgres_server_admin_username"></a> [postgres\_server\_admin\_username](#input\_postgres\_server\_admin\_username) | The username of the admin user of the PostgreSQL Server. | `string` | `"nebulyadmin"` | no |
| <a name="input_postgres_server_alert_rules"></a> [postgres\_server\_alert\_rules](#input\_postgres\_server\_alert\_rules) | The Azure Monitor alert rules to set on the provisioned PostgreSQL server. | <pre>map(object({<br>    description     = string<br>    frequency       = string<br>    window_size     = string<br>    action_group_id = string<br>    severity        = number<br><br>    criteria = optional(<br>      object({<br>        aggregation = string<br>        metric_name = string<br>        operator    = string<br>        threshold   = number<br>      })<br>    , null)<br>    dynamic_criteria = optional(<br>      object({<br>        aggregation       = string<br>        metric_name       = string<br>        operator          = string<br>        alert_sensitivity = string<br>      })<br>    , null)<br>  }))</pre> | `{}` | no |
| <a name="input_postgres_server_high_availability"></a> [postgres\_server\_high\_availability](#input\_postgres\_server\_high\_availability) | High-availability configuration of the DB server. Possible values for mode are: SameZone or ZoneRedundant. | <pre>object({<br>    enabled : bool<br>    mode : string<br>    standby_availability_zone : optional(string, null)<br>  })</pre> | <pre>{<br>  "enabled": true,<br>  "mode": "SameZone"<br>}</pre> | no |
| <a name="input_postgres_server_lock"></a> [postgres\_server\_lock](#input\_postgres\_server\_lock) | Optionally lock the PostgreSQL server to prevent deletion. | <pre>object({<br>    enabled = optional(bool, false)<br>    notes   = optional(string, "Cannot be deleted.")<br>    name    = optional(string, "terraform-lock")<br>  })</pre> | <pre>{<br>  "enabled": true<br>}</pre> | no |
| <a name="input_postgres_server_maintenance_window"></a> [postgres\_server\_maintenance\_window](#input\_postgres\_server\_maintenance\_window) | The window for performing automatic maintenance of the PostgreSQL Server. Default is Sunday at 00:00 of the timezone of the server location. | <pre>object({<br>    day_of_week : number<br>    start_hour : number<br>    start_minute : number<br>  })</pre> | <pre>{<br>  "day_of_week": 0,<br>  "start_hour": 0,<br>  "start_minute": 0<br>}</pre> | no |
| <a name="input_postgres_server_max_storage_mb"></a> [postgres\_server\_max\_storage\_mb](#input\_postgres\_server\_max\_storage\_mb) | The max storage allowed for the PostgreSQL Flexible Server. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216 and 33553408. | `number` | `262144` | no |
| <a name="input_postgres_server_networking"></a> [postgres\_server\_networking](#input\_postgres\_server\_networking) | Server networking configuration. <br><br>  If allowed\_ip\_ranges is not empty, then the server is accessible from <br>  the Internet through the configured firewall rules.<br><br>  If delegated\_subnet\_id or private\_dns\_zone\_id are provided, then the Server <br>  is accessible only from the specified virutal network. | <pre>object({<br>    allowed_ip_ranges : optional(list(object({<br>      name : string<br>      start_ip_address : string<br>      end_ip_address : string<br>    })), [])<br>    delegated_subnet_id : optional(string, null)<br>    private_dns_zone_id : optional(string, null)<br>    public_network_access_enabled : optional(bool, false)<br>  })</pre> | n/a | yes |
| <a name="input_postgres_server_optional_configurations"></a> [postgres\_server\_optional\_configurations](#input\_postgres\_server\_optional\_configurations) | Optional Flexible PostgreSQL configurations. Defaults to recommended configurations. | `map(string)` | <pre>{<br>  "intelligent_tuning": "on",<br>  "intelligent_tuning.metric_targets": "ALL",<br>  "metrics.autovacuum_diagnostics": "on",<br>  "metrics.collector_database_activity": "on",<br>  "pg_qs.query_capture_mode": "ALL",<br>  "pg_qs.retention_period_in_days": "7",<br>  "pg_qs.store_query_plans": "on",<br>  "pgaudit.log": "WRITE",<br>  "pgms_wait_sampling.query_capture_mode": "ALL",<br>  "track_io_timing": "on"<br>}</pre> | no |
| <a name="input_postgres_server_point_in_time_backup"></a> [postgres\_server\_point\_in\_time\_backup](#input\_postgres\_server\_point\_in\_time\_backup) | The backup settings of the PostgreSQL Server. | <pre>object({<br>    geo_redundant : optional(bool, true)<br>    retention_days : optional(number, 30)<br>  })</pre> | <pre>{<br>  "geo_redundant": true,<br>  "retention_days": 30<br>}</pre> | no |
| <a name="input_postgres_server_sku"></a> [postgres\_server\_sku](#input\_postgres\_server\_sku) | The SKU of the PostgreSQL Server, including the Tier and the Name. Examples: B\_Standard\_B1ms, GP\_Standard\_D2s\_v3, MO\_Standard\_E4s\_v3 | <pre>object({<br>    tier : string<br>    name : string<br>  })</pre> | <pre>{<br>  "name": "Standard_D4ds_v5",<br>  "tier": "GP"<br>}</pre> | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | The PostgreSQL version to use. | `string` | `"16"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group where to provision the resources. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | The prefix that will be used for generating resource names. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags that will be applied to all resources. | `map(string)` | `{}` | no |

## Resources


- resource.azurerm_key_vault.main (/terraform-docs/main.tf#187)
- resource.azurerm_management_lock.postgres_server (/terraform-docs/main.tf#126)
- resource.azurerm_monitor_metric_alert.postgres_server_alerts (/terraform-docs/main.tf#134)
- resource.azurerm_postgresql_flexible_server.main (/terraform-docs/main.tf#52)
- resource.azurerm_postgresql_flexible_server_configuration.mandatory_configurations (/terraform-docs/main.tf#103)
- resource.azurerm_postgresql_flexible_server_configuration.optional_configurations (/terraform-docs/main.tf#96)
- resource.azurerm_postgresql_flexible_server_database.main (/terraform-docs/main.tf#118)
- resource.azurerm_postgresql_flexible_server_firewall_rule.main (/terraform-docs/main.tf#110)
- resource.azurerm_private_endpoint.key_vault (/terraform-docs/main.tf#213)
- resource.random_password.postgres_server_admin_password (/terraform-docs/main.tf#47)
- data source.azurerm_client_config.current (/terraform-docs/main.tf#42)
- data source.azurerm_resource_group.main (/terraform-docs/main.tf#39)
