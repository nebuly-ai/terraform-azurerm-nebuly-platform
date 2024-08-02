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
| <a name="input_location"></a> [location](#input\_location) | The region where to provision the resources. | `string` | n/a | yes |
| <a name="input_openai_api_key"></a> [openai\_api\_key](#input\_openai\_api\_key) | The API Key used for authenticating with OpenAI. | `string` | n/a | yes |
| <a name="input_postgres_server_admin_username"></a> [postgres\_server\_admin\_username](#input\_postgres\_server\_admin\_username) | The username of the admin user of the PostgreSQL Server. | `string` | `"nebulyadmin"` | no |
| <a name="input_postgres_server_high_availability"></a> [postgres\_server\_high\_availability](#input\_postgres\_server\_high\_availability) | High-availability configuration of the DB server. Possible values for mode are: SameZone or ZoneRedundant. | <pre>object({<br>    enabled : bool<br>    mode : string<br>    standby_availability_zone : optional(string, null)<br>  })</pre> | n/a | yes |
| <a name="input_postgres_server_maintenance_window"></a> [postgres\_server\_maintenance\_window](#input\_postgres\_server\_maintenance\_window) | The window for performing automatic maintenance of the PostgreSQL Server. Default is Sunday at 00:00 of the timezone of the server location. | <pre>object({<br>    day_of_week : number<br>    start_hour : number<br>    start_minute : number<br>  })</pre> | <pre>{<br>  "day_of_week": 0,<br>  "start_hour": 0,<br>  "start_minute": 0<br>}</pre> | no |
| <a name="input_postgres_server_max_storage_mb"></a> [postgres\_server\_max\_storage\_mb](#input\_postgres\_server\_max\_storage\_mb) | The max storage allowed for the PostgreSQL Flexible Server. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216 and 33553408. | `number` | `262144` | no |
| <a name="input_postgres_server_networking"></a> [postgres\_server\_networking](#input\_postgres\_server\_networking) | Server networking configuration. <br><br>  If allowed\_ip\_ranges is not empty, then the server is accessible from <br>  the Internet through the configured firewall rules.<br><br>  If delegated\_subnet\_id or private\_dns\_zone\_id are provided, then the Server <br>  is accessible only from the specified virutal network. | <pre>object({<br>    allowed_ip_ranges : optional(list(object({<br>      name : string<br>      start_ip_address : string<br>      end_ip_address : string<br>    })), [])<br>    delegated_subnet_id : optional(string, null)<br>    private_dns_zone_id : optional(string, null)<br>    public_network_access_enabled : optional(bool, false)<br>  })</pre> | n/a | yes |
| <a name="input_postgres_server_point_in_time_backup"></a> [postgres\_server\_point\_in\_time\_backup](#input\_postgres\_server\_point\_in\_time\_backup) | The backup settings of the PostgreSQL Server. | <pre>object({<br>    geo_redundant : optional(bool, true)<br>    retention_days : optional(number, 30)<br>  })</pre> | n/a | yes |
| <a name="input_postgres_server_sku"></a> [postgres\_server\_sku](#input\_postgres\_server\_sku) | The SKU of the PostgreSQL Server, including the Tier and the Name. Examples: B\_Standard\_B1ms, GP\_Standard\_D2s\_v3, MO\_Standard\_E4s\_v3 | <pre>object({<br>    tier : string<br>    name : string<br>  })</pre> | <pre>{<br>  "name": "Standard_D4ds_v5",<br>  "tier": "GP"<br>}</pre> | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | The PostgreSQL version to use. | `string` | `"16"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group where to provision the resources. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | The prefix that will be used for generating resource names. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags that will be applied to all resources. | `map(string)` | `{}` | no |

## Resources


- resource.azurerm_postgresql_flexible_server.main (/terraform-docs/main.tf#37)
- resource.random_password.postgres_server_admin_password (/terraform-docs/main.tf#32)
- data source.azurerm_resource_group.main (/terraform-docs/main.tf#27)
