# Nebuly Platform (Azure)

Terraform module for provisioning Nebuly Platform resources on Microsoft Azure.

Available on [Terraform Registry](https://registry.terraform.io/modules/nebuly-ai/nebuly-platform/azurerm/latest).

## Quickstart

To get started with Nebuly installation on Microsoft Azure, you can follow the steps below. 

These instructions will guide you through the installation using Nebuly's default standard configuration with the Nebuly Helm Chart.

For specific configurations or assistance, reach out to the Nebuly Slack channel or email [support@nebuly.ai](mailto:support@nebuly.ai).

### 1. Terraform setup

Import Nebuly into your Terraform root module, provide the necessary variables, and apply the changes.

For configuration examples, you can refer to the [Examples](#examples). 

Once the Terraform changes are applied, proceed with the next steps to deploy Nebuly on the provisioned Azure Kubernetes Service (AKS) cluster.

### 2. Connect to the Azure Kubernetes Service cluster

Prerequisites: install the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli).

* Fetch the command for retrieving the credentials from the module outputs:

```shell
terraform output aks_get_credentials
```

* Run the command you got from the previous step

### 3. Create image pull secret

The auto-generated Helm values use the name defined in the k8s_image_pull_secret_name input variable for the Image Pull Secret. If you prefer a custom name, update either the Terraform variable or your Helm values accordingly.
Create a Kubernetes [Image Pull Secret](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) for 
authenticating with your Docker registry and pulling the Nebuly Docker images.


### 4. Create Secret Provider Class
Create a Secret Provider Class to allow AKS to fetch credentials from the provisioned Key Vault.

* Get the Secret Provider Class YAML definition from the Terraform module outputs:
  ```shell
  terraform output secret_provider_class
  ```

* Copy the output of the command into a file named secret-provider-class.yaml.

* Run the following commands to install Nebuly in the Kubernetes namespace nebuly:

  ```shell
  kubectl create ns nebuly
  kubectl apply --server-side -f secret-provider-class.yaml
  ```

### 5. Bootstrap AKS cluster

Install the bootstrap Helm chart to set up all the dependencies required for installing the Nebuly Platform Helm chart on AKS.

Refer to the [chart documentation](https://github.com/nebuly-ai/helm-charts/tree/main/bootstrap-azure) for all the configuration details.

```shell
helm install oci://ghcr.io/nebuly-ai/helm-charts/bootstrap-azure \
  --namespace nebuly \
  --generate-name 
```

### 6. Install nebuly-platform chart

Retrieve the auto-generated values from the Terraform outputs and save them to a file named `values.yaml`:

```shell
terraform output helm_values
```

Install the Nebuly Next, install the Nebuly Platform Helm chart. 
Refer to the [chart documentation](https://github.com/nebuly-ai/helm-charts/tree/main/nebuly-platform) for detailed configuration options.

```shell
helm install oci://ghcr.io/nebuly-ai/helm-charts/nebuly-platform \
  --namespace nebuly \
  -f values.yaml \
  <your-release-name> 
```


## Examples

You can find examples of code that uses this Terraform module in the [examples](./examples) directory.





## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ~>2.53 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~>3.114 |
| <a name="provider_http"></a> [http](#provider\_http) | ~>3.4 |
| <a name="provider_random"></a> [random](#provider\_random) | ~>3.6 |
| <a name="provider_time"></a> [time](#provider\_time) | ~>0.12 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~>4.0 |


## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aks_get_credentials"></a> [aks\_get\_credentials](#output\_aks\_get\_credentials) | Command for getting the credentials for connecting to the provisioned AKS cluster. |
| <a name="output_helm_values"></a> [helm\_values](#output\_helm\_values) | The `values.yaml` file for installing Nebuly with Helm.<br><br>  The default standard configuration is used, which uses Nginx as ingress controller and exposes the application to the Internet. This configuration can be customized according to specific needs. |
| <a name="output_secret_provider_class"></a> [secret\_provider\_class](#output\_secret\_provider\_class) | The `secret-provider-class.yaml` file to make Kubernetes reference the secrets stored in the Key Vault. |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aks_cluster_admin_object_ids"></a> [aks\_cluster\_admin\_object\_ids](#input\_aks\_cluster\_admin\_object\_ids) | Object IDs that are granted the Cluster Admin role over the AKS cluster | `set(string)` | n/a | yes |
| <a name="input_aks_kubernetes_version"></a> [aks\_kubernetes\_version](#input\_aks\_kubernetes\_version) | The Kubernetes version to use. | `string` | `"1.29.5"` | no |
| <a name="input_aks_log_analytics_workspace"></a> [aks\_log\_analytics\_workspace](#input\_aks\_log\_analytics\_workspace) | Existing azurerm\_log\_analytics\_workspace to attach azurerm\_log\_analytics\_solution. Providing the config disables creation of azurerm\_log\_analytics\_workspace. | <pre>object({<br>    id                  = string<br>    name                = string<br>    location            = optional(string)<br>    resource_group_name = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_aks_net_profile_dns_service_ip"></a> [aks\_net\_profile\_dns\_service\_ip](#input\_aks\_net\_profile\_dns\_service\_ip) | IP address within the Kubernetes service address range that is used by cluster service discovery (kube-dns). Must be inluced in net\_profile\_cidr. Example: 10.32.0.10 | `string` | `"10.32.0.10"` | no |
| <a name="input_aks_net_profile_service_cidr"></a> [aks\_net\_profile\_service\_cidr](#input\_aks\_net\_profile\_service\_cidr) | The Network Range used by the Kubernetes service. Must not overlap with the AKS Nodes address space. Example: 10.32.0.0/24 | `string` | `"10.32.0.0/24"` | no |
| <a name="input_aks_sku_tier"></a> [aks\_sku\_tier](#input\_aks\_sku\_tier) | The AKS tier. Possible values are: Free, Standard, Premium. It is recommended to use Standard or Premium for production workloads. | `string` | `"Standard"` | no |
| <a name="input_aks_sys_pool"></a> [aks\_sys\_pool](#input\_aks\_sys\_pool) | The configuration of the AKS System Nodes Pool. | <pre>object({<br>    vm_size : string<br>    nodes_max_pods : number<br>    name : string<br>    availability_zones : list(string)<br>    disk_size_gb : number<br>    disk_type : string<br>    nodes_labels : optional(map(string), {})<br>    nodes_tags : optional(map(string), {})<br>    only_critical_addons_enabled : optional(bool, false)<br>    # Auto-scaling settings<br>    nodes_count : optional(number, null)<br>    enable_auto_scaling : optional(bool, false)<br>    agents_min_count : optional(number, null)<br>    agents_max_count : optional(number, null)<br>  })</pre> | <pre>{<br>  "agents_max_count": 3,<br>  "agents_min_count": 1,<br>  "availability_zones": [<br>    "1",<br>    "2",<br>    "3"<br>  ],<br>  "disk_size_gb": 128,<br>  "disk_type": "Ephemeral",<br>  "enable_auto_scaling": true,<br>  "name": "system",<br>  "nodes_max_pods": 60,<br>  "only_critical_addons_enabled": false,<br>  "vm_size": "Standard_E4ads_v5"<br>}</pre> | no |
| <a name="input_aks_worker_pools"></a> [aks\_worker\_pools](#input\_aks\_worker\_pools) | The worker pools of the AKS cluster, each with the respective configuration.<br>  The default configuration uses a single worker node, with no HA. | <pre>map(object({<br>    enabled : optional(bool, true)<br>    vm_size : string<br>    priority : optional(string, "Regular")<br>    tags : map(string)<br>    max_pods : number<br>    disk_size_gb : optional(number, 128)<br>    disk_type : string<br>    availability_zones : list(string)<br>    node_taints : optional(list(string), [])<br>    node_labels : optional(map(string), {})<br>    # Auto-scaling settings<br>    nodes_count : optional(number, null)<br>    enable_auto_scaling : optional(bool, false)<br>    nodes_min_count : optional(number, null)<br>    nodes_max_count : optional(number, null)<br>  }))</pre> | <pre>{<br>  "a100w01": {<br>    "availability_zones": [<br>      "1"<br>    ],<br>    "disk_size_gb": 128,<br>    "disk_type": "Ephemeral",<br>    "enable_auto_scaling": true,<br>    "max_pods": 30,<br>    "node_labels": {<br>      "nebuly.com/accelerator": "nvidia-ampere-a100"<br>    },<br>    "node_taints": [<br>      "nvidia.com/gpu=:NoSchedule"<br>    ],<br>    "nodes_count": null,<br>    "nodes_max_count": 1,<br>    "nodes_min_count": 0,<br>    "priority": "Regular",<br>    "tags": {},<br>    "vm_size": "Standard_NC24ads_A100_v4"<br>  },<br>  "a100w02": {<br>    "availability_zones": [<br>      "2"<br>    ],<br>    "disk_size_gb": 128,<br>    "disk_type": "Ephemeral",<br>    "enable_auto_scaling": true,<br>    "max_pods": 30,<br>    "node_labels": {<br>      "nebuly.com/accelerator": "nvidia-ampere-a100"<br>    },<br>    "node_taints": [<br>      "nvidia.com/gpu=:NoSchedule"<br>    ],<br>    "nodes_count": null,<br>    "nodes_max_count": 1,<br>    "nodes_min_count": 0,<br>    "priority": "Regular",<br>    "tags": {},<br>    "vm_size": "Standard_NC24ads_A100_v4"<br>  },<br>  "a100w03": {<br>    "availability_zones": [<br>      "3"<br>    ],<br>    "disk_size_gb": 128,<br>    "disk_type": "Ephemeral",<br>    "enable_auto_scaling": true,<br>    "max_pods": 30,<br>    "node_labels": {<br>      "nebuly.com/accelerator": "nvidia-ampere-a100"<br>    },<br>    "node_taints": [<br>      "nvidia.com/gpu=:NoSchedule"<br>    ],<br>    "nodes_count": null,<br>    "nodes_max_count": 1,<br>    "nodes_min_count": 0,<br>    "priority": "Regular",<br>    "tags": {},<br>    "vm_size": "Standard_NC24ads_A100_v4"<br>  },<br>  "t4workers": {<br>    "availability_zones": [<br>      "1",<br>      "2",<br>      "3"<br>    ],<br>    "disk_size_gb": 128,<br>    "disk_type": "Ephemeral",<br>    "enable_auto_scaling": true,<br>    "max_pods": 30,<br>    "node_labels": {<br>      "nebuly.com/accelerator": "nvidia-tesla-t4"<br>    },<br>    "node_taints": [<br>      "nvidia.com/gpu=:NoSchedule"<br>    ],<br>    "nodes_count": null,<br>    "nodes_max_count": 1,<br>    "nodes_min_count": 0,<br>    "priority": "Regular",<br>    "tags": {},<br>    "vm_size": "Standard_NC4as_T4_v3"<br>  }<br>}</pre> | no |
| <a name="input_azure_openai_location"></a> [azure\_openai\_location](#input\_azure\_openai\_location) | The Azure region where to deploy the Azure OpenAI models. <br>  Note that the models required by Nebuly are supported only in few specific regions. For more information, you can refer to Azure documentation:<br>  https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#standard-deployment-model-availability | `string` | `"EastUS"` | no |
| <a name="input_azure_openai_rate_limits"></a> [azure\_openai\_rate\_limits](#input\_azure\_openai\_rate\_limits) | The rate limits (K-tokens/minute) of the deployed Azure OpenAI models. | <pre>object({<br>    gpt_4 : number<br>    gpt_4o_mini : number<br>  })</pre> | <pre>{<br>  "gpt_4": 100,<br>  "gpt_4o_mini": 100<br>}</pre> | no |
| <a name="input_k8s_image_pull_secret_name"></a> [k8s\_image\_pull\_secret\_name](#input\_k8s\_image\_pull\_secret\_name) | The name of the Kubernetes Image Pull Secret to use. <br>  This value will be used to auto-generate the values.yaml file for installing the Nebuly Platform Helm chart. | `string` | `"nebuly-docker-pull"` | no |
| <a name="input_key_vault_public_network_access_enabled"></a> [key\_vault\_public\_network\_access\_enabled](#input\_key\_vault\_public\_network\_access\_enabled) | Can the Key Vault be accessed from the Internet, according to the firewall rules?<br>  Default to true to to allow the Terraform module to be executed even outside the private virtual network. <br>  When set to true, firewall rules are applied, and all connections are denied by default. | `bool` | `true` | no |
| <a name="input_key_vault_purge_protection_enabled"></a> [key\_vault\_purge\_protection\_enabled](#input\_key\_vault\_purge\_protection\_enabled) | Is purge protection enabled for the Key Vault? | `bool` | `false` | no |
| <a name="input_key_vault_sku_name"></a> [key\_vault\_sku\_name](#input\_key\_vault\_sku\_name) | The SKU of the Key Vault. | `string` | `"Standard"` | no |
| <a name="input_key_vault_soft_delete_retention_days"></a> [key\_vault\_soft\_delete\_retention\_days](#input\_key\_vault\_soft\_delete\_retention\_days) | The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days. | `number` | `7` | no |
| <a name="input_location"></a> [location](#input\_location) | The region where to provision the resources. | `string` | n/a | yes |
| <a name="input_nebuly_credentials"></a> [nebuly\_credentials](#input\_nebuly\_credentials) | The credentials provided by Nebuly are required for activating your platform installation. <br>  If you haven't received your credentials or have lost them, please contact support@nebuly.ai. | <pre>object({<br>    client_id : string<br>    client_secret : string<br>  })</pre> | n/a | yes |
| <a name="input_platform_domain"></a> [platform\_domain](#input\_platform\_domain) | The domain on which the deployed Nebuly platform is made accessible. | `string` | n/a | yes |
| <a name="input_postgres_server_admin_username"></a> [postgres\_server\_admin\_username](#input\_postgres\_server\_admin\_username) | The username of the admin user of the PostgreSQL Server. | `string` | `"nebulyadmin"` | no |
| <a name="input_postgres_server_alert_rules"></a> [postgres\_server\_alert\_rules](#input\_postgres\_server\_alert\_rules) | The Azure Monitor alert rules to set on the provisioned PostgreSQL server. | <pre>map(object({<br>    description     = string<br>    frequency       = string<br>    window_size     = string<br>    action_group_id = string<br>    severity        = number<br><br>    criteria = optional(<br>      object({<br>        aggregation = string<br>        metric_name = string<br>        operator    = string<br>        threshold   = number<br>      })<br>    , null)<br>    dynamic_criteria = optional(<br>      object({<br>        aggregation       = string<br>        metric_name       = string<br>        operator          = string<br>        alert_sensitivity = string<br>      })<br>    , null)<br>  }))</pre> | `{}` | no |
| <a name="input_postgres_server_high_availability"></a> [postgres\_server\_high\_availability](#input\_postgres\_server\_high\_availability) | High-availability configuration of the DB server. Possible values for mode are: SameZone or ZoneRedundant. | <pre>object({<br>    enabled : bool<br>    mode : optional(string, "SameZone")<br>    standby_availability_zone : optional(string, null)<br>  })</pre> | <pre>{<br>  "enabled": true,<br>  "mode": "SameZone"<br>}</pre> | no |
| <a name="input_postgres_server_lock"></a> [postgres\_server\_lock](#input\_postgres\_server\_lock) | Optionally lock the PostgreSQL server to prevent deletion. | <pre>object({<br>    enabled = optional(bool, false)<br>    notes   = optional(string, "Cannot be deleted.")<br>    name    = optional(string, "terraform-lock")<br>  })</pre> | <pre>{<br>  "enabled": true<br>}</pre> | no |
| <a name="input_postgres_server_maintenance_window"></a> [postgres\_server\_maintenance\_window](#input\_postgres\_server\_maintenance\_window) | The window for performing automatic maintenance of the PostgreSQL Server. Default is Sunday at 00:00 of the timezone of the server location. | <pre>object({<br>    day_of_week : number<br>    start_hour : number<br>    start_minute : number<br>  })</pre> | <pre>{<br>  "day_of_week": 0,<br>  "start_hour": 0,<br>  "start_minute": 0<br>}</pre> | no |
| <a name="input_postgres_server_max_storage_mb"></a> [postgres\_server\_max\_storage\_mb](#input\_postgres\_server\_max\_storage\_mb) | The max storage allowed for the PostgreSQL Flexible Server. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216 and 33553408. | `number` | `262144` | no |
| <a name="input_postgres_server_optional_configurations"></a> [postgres\_server\_optional\_configurations](#input\_postgres\_server\_optional\_configurations) | Optional Flexible PostgreSQL configurations. Defaults to recommended configurations. | `map(string)` | <pre>{<br>  "intelligent_tuning": "on",<br>  "intelligent_tuning.metric_targets": "ALL",<br>  "metrics.autovacuum_diagnostics": "on",<br>  "metrics.collector_database_activity": "on",<br>  "pg_qs.query_capture_mode": "ALL",<br>  "pg_qs.retention_period_in_days": "7",<br>  "pg_qs.store_query_plans": "on",<br>  "pgaudit.log": "WRITE",<br>  "pgms_wait_sampling.query_capture_mode": "ALL",<br>  "track_io_timing": "on"<br>}</pre> | no |
| <a name="input_postgres_server_point_in_time_backup"></a> [postgres\_server\_point\_in\_time\_backup](#input\_postgres\_server\_point\_in\_time\_backup) | The backup settings of the PostgreSQL Server. | <pre>object({<br>    geo_redundant : optional(bool, true)<br>    retention_days : optional(number, 30)<br>  })</pre> | <pre>{<br>  "geo_redundant": true,<br>  "retention_days": 30<br>}</pre> | no |
| <a name="input_postgres_server_sku"></a> [postgres\_server\_sku](#input\_postgres\_server\_sku) | The SKU of the PostgreSQL Server, including the Tier and the Name. Examples: B\_Standard\_B1ms, GP\_Standard\_D2s\_v3, MO\_Standard\_E4s\_v3 | <pre>object({<br>    tier : string<br>    name : string<br>  })</pre> | <pre>{<br>  "name": "Standard_D4ds_v5",<br>  "tier": "GP"<br>}</pre> | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | The PostgreSQL version to use. | `string` | `"16"` | no |
| <a name="input_private_dns_zones"></a> [private\_dns\_zones](#input\_private\_dns\_zones) | Private DNS zones to use for Private Endpoint connections. If not provided, a new DNS Zone <br>  is created and linked to the respective subnet. | <pre>object({<br>    flexible_postgres = optional(object({<br>      name : string<br>      id : string<br>    }), null)<br>  })</pre> | `{}` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group where to provision the resources. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | The prefix that is used for generating resource names. | `string` | n/a | yes |
| <a name="input_subnet_address_space_aks_nodes"></a> [subnet\_address\_space\_aks\_nodes](#input\_subnet\_address\_space\_aks\_nodes) | Address space of the new subnet in which to create the nodes of the AKS cluster. <br>  If `subnet_name_aks_nodes` is provided, the existing subnet is used and this variable is ignored. | `list(string)` | <pre>[<br>  "10.0.0.0/22"<br>]</pre> | no |
| <a name="input_subnet_address_space_flexible_postgres"></a> [subnet\_address\_space\_flexible\_postgres](#input\_subnet\_address\_space\_flexible\_postgres) | Address space of the new subnet delgated to Flexible PostgreSQL Server service. <br>  If `subnet_name_flexible_postgres` is provided, the existing subnet is used and this variable is ignored. | `list(string)` | <pre>[<br>  "10.0.12.0/26"<br>]</pre> | no |
| <a name="input_subnet_address_space_private_endpoints"></a> [subnet\_address\_space\_private\_endpoints](#input\_subnet\_address\_space\_private\_endpoints) | Address space of the new subnet in which to create private endpoints. <br>  If `subnet_name_private_endpoints` is provided, the existing subnet is used and this variable is ignored. | `list(string)` | <pre>[<br>  "10.0.8.0/26"<br>]</pre> | no |
| <a name="input_subnet_name_aks_nodes"></a> [subnet\_name\_aks\_nodes](#input\_subnet\_name\_aks\_nodes) | Optional name of the subnet to be used for provisioning AKS nodes.<br>  If not provided, a new subnet is created. | `string` | `null` | no |
| <a name="input_subnet_name_flexible_postgres"></a> [subnet\_name\_flexible\_postgres](#input\_subnet\_name\_flexible\_postgres) | Optional name of the subnet delegated to Flexible PostgreSQL Server service. <br>  If not provided, a new subnet is created. | `string` | `null` | no |
| <a name="input_subnet_name_private_endpoints"></a> [subnet\_name\_private\_endpoints](#input\_subnet\_name\_private\_endpoints) | Optional name of the subnet to which attach the Private Endpoints. <br>  If not provided, a new subnet is created. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags that are applied to all resources. | `map(string)` | `{}` | no |
| <a name="input_virtual_network_address_space"></a> [virtual\_network\_address\_space](#input\_virtual\_network\_address\_space) | Address space of the new virtual network in which to create resources. <br>  If `virtual_network_name` is provided, the existing virtual network is used and this variable is ignored. | `list(string)` | <pre>[<br>  "10.0.0.0/16"<br>]</pre> | no |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | Optional name of the virtual network in which to create the resources. <br>  If not provided, a new virtual network is created. | `string` | `null` | no |
| <a name="input_whitelist_current_ip"></a> [whitelist\_current\_ip](#input\_whitelist\_current\_ip) | If true, add the current IP executing the Terraform module to the whitelist rules of the provisioned services. <br>  This allows Terraform to access and configure the resources even when running outside the virtual network.<br><br>  The whitelisting excludes the Database Server, which remains unexposed to the Internet and is accessible only from the virtual network. | `bool` | `true` | no |
| <a name="input_whitelisted_ips"></a> [whitelisted\_ips](#input\_whitelisted\_ips) | Optional list of IPs that will be able to access the following resources from the internet: Azure Kubernetes Service (AKS) API Server, <br>  Azure Key Vault, Azure Storage Account. | `list(string)` | `[]` | no |

## Resources


- resource.azuread_application.main (/terraform-docs/main.tf#234)
- resource.azuread_service_principal.main (/terraform-docs/main.tf#240)
- resource.azuread_service_principal_password.main (/terraform-docs/main.tf#245)
- resource.azurerm_cognitive_account.main (/terraform-docs/main.tf#452)
- resource.azurerm_cognitive_deployment.gpt_4_turbo (/terraform-docs/main.tf#471)
- resource.azurerm_cognitive_deployment.gpt_4o_mini (/terraform-docs/main.tf#486)
- resource.azurerm_key_vault.main (/terraform-docs/main.tf#193)
- resource.azurerm_key_vault_secret.azure_openai_api_key (/terraform-docs/main.tf#501)
- resource.azurerm_key_vault_secret.azuread_application_client_id (/terraform-docs/main.tf#249)
- resource.azurerm_key_vault_secret.azuread_application_client_secret (/terraform-docs/main.tf#258)
- resource.azurerm_key_vault_secret.jwt_signing_key (/terraform-docs/main.tf#681)
- resource.azurerm_key_vault_secret.nebuly_azure_client_id (/terraform-docs/main.tf#271)
- resource.azurerm_key_vault_secret.nebuly_azure_client_secret (/terraform-docs/main.tf#280)
- resource.azurerm_key_vault_secret.postgres_password (/terraform-docs/main.tf#435)
- resource.azurerm_key_vault_secret.postgres_user (/terraform-docs/main.tf#426)
- resource.azurerm_kubernetes_cluster_node_pool.linux_pools (/terraform-docs/main.tf#638)
- resource.azurerm_management_lock.postgres_server (/terraform-docs/main.tf#369)
- resource.azurerm_monitor_metric_alert.postgres_server_alerts (/terraform-docs/main.tf#377)
- resource.azurerm_postgresql_flexible_server.main (/terraform-docs/main.tf#299)
- resource.azurerm_postgresql_flexible_server_configuration.mandatory_configurations (/terraform-docs/main.tf#350)
- resource.azurerm_postgresql_flexible_server_configuration.optional_configurations (/terraform-docs/main.tf#343)
- resource.azurerm_postgresql_flexible_server_database.analytics (/terraform-docs/main.tf#363)
- resource.azurerm_postgresql_flexible_server_database.auth (/terraform-docs/main.tf#357)
- resource.azurerm_private_dns_zone.flexible_postgres (/terraform-docs/main.tf#172)
- resource.azurerm_private_dns_zone_virtual_network_link.flexible_postgres (/terraform-docs/main.tf#178)
- resource.azurerm_role_assignment.aks_network_contributor (/terraform-docs/main.tf#633)
- resource.azurerm_role_assignment.key_vault_secret_officer__current (/terraform-docs/main.tf#224)
- resource.azurerm_role_assignment.key_vault_secret_user__aks (/terraform-docs/main.tf#216)
- resource.azurerm_role_assignment.storage_container_models__data_contributor (/terraform-docs/main.tf#539)
- resource.azurerm_storage_account.main (/terraform-docs/main.tf#515)
- resource.azurerm_storage_container.models (/terraform-docs/main.tf#535)
- resource.azurerm_subnet.aks_nodes (/terraform-docs/main.tf#128)
- resource.azurerm_subnet.flexible_postgres (/terraform-docs/main.tf#150)
- resource.azurerm_subnet.private_endpints (/terraform-docs/main.tf#142)
- resource.azurerm_virtual_network.main (/terraform-docs/main.tf#120)
- resource.random_password.postgres_server_admin_password (/terraform-docs/main.tf#294)
- resource.time_sleep.wait_aks_creation (/terraform-docs/main.tf#620)
- resource.tls_private_key.aks (/terraform-docs/main.tf#549)
- resource.tls_private_key.jwt_signing_key (/terraform-docs/main.tf#677)
- data source.azurerm_client_config.current (/terraform-docs/main.tf#78)
- data source.azurerm_resource_group.main (/terraform-docs/main.tf#75)
- data source.azurerm_subnet.aks_nodes (/terraform-docs/main.tf#89)
- data source.azurerm_subnet.flexible_postgres (/terraform-docs/main.tf#103)
- data source.azurerm_virtual_network.main (/terraform-docs/main.tf#83)
- data source.http_http.current_ip (/terraform-docs/main.tf#80)
