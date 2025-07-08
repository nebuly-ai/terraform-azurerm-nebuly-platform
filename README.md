# Nebuly Platform (Azure)

Terraform module for provisioning Nebuly Platform resources on Microsoft Azure.

Available on [Terraform Registry](https://registry.terraform.io/modules/nebuly-ai/nebuly-platform/azurerm/latest).


## Prerequisite

### Nebuly Credentials

Before using this Terraform module, ensure that you have your Nebuly credentials ready. 
These credentials are necessary to activate your installation and should be provided as input via the `nebuly_credentials` input.

### Required Azure Quotas

Ensure that you have the necessary Azure quotas available to provision the resources required for the Nebuly Platform:

* **Standard NCADS_A100_v4 Family vCPUs**: at least 24 vCPUs
* **Azure OpenAI gpt-4o**: at least 80k tokens per minute

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

### 4. Bootstrap AKS cluster

Retrieve the auto-generated values from the Terraform outputs and save them to a file named `values-bootstrap.yaml`:

```shell
terraform output helm_values_bootstrap
```

Install the bootstrap Helm chart to set up all the dependencies required for installing the Nebuly Platform Helm chart on AKS.

Refer to the [chart documentation](https://github.com/nebuly-ai/helm-charts/tree/main/bootstrap-azure) for all the configuration details.

```shell
helm install oci://ghcr.io/nebuly-ai/helm-charts/bootstrap-azure \
  --namespace nebuly-bootstrap \
  --generate-name \
  --create-namespace \
  -f values-bootstrap.yaml
```

### 5. Create Secret Provider Class
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

### 6. Install nebuly-platform chart

Retrieve the auto-generated values from the Terraform outputs and save them to a file named `values.yaml`:

```shell
terraform output helm_values
```

Install the Nebuly Platform Helm chart. 
Refer to the [chart documentation](https://github.com/nebuly-ai/helm-charts/tree/main/nebuly-platform) for detailed configuration options.

```shell
helm install <your-release-name> oci://ghcr.io/nebuly-ai/helm-charts/nebuly-platform \
  --namespace nebuly \
  -f values.yaml \
  --timeout 30m 
```

> ℹ️  During the initial installation of the chart, all required Nebuly LLMs are uploaded to your model registry. 
> This process can take approximately 5 minutes. If the helm install command appears to be stuck, don't worry: it's simply waiting for the upload to finish.

### 7. Access Nebuly

Retrieve the IP of the Load Balancer to access the Nebuly Platform:

```shell
kubectl get svc -n nebuly-bootstrap -o jsonpath='{range .items[?(@.status.loadBalancer.ingress)]}{.status.loadBalancer.ingress[0].ip}{"\n"}{end}'
```

You can then register a DNS A record pointing to the Load Balancer IP address to access Nebuly via the custom domain you provided 
in the input variable `platform_domain`.


## Examples

You can find examples of code that uses this Terraform module in the [examples](./examples) directory.





## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ~>2.53 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~>3.114 |
| <a name="provider_random"></a> [random](#provider\_random) | ~>3.6 |
| <a name="provider_time"></a> [time](#provider\_time) | ~>0.12 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~>4.0 |


## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aks_get_credentials"></a> [aks\_get\_credentials](#output\_aks\_get\_credentials) | Command for getting the credentials for connecting to the provisioned AKS cluster. |
| <a name="output_azurerm_key_vault"></a> [azurerm\_key\_vault](#output\_azurerm\_key\_vault) | The Key Vault resource. |
| <a name="output_azurerm_kubernetes_cluster"></a> [azurerm\_kubernetes\_cluster](#output\_azurerm\_kubernetes\_cluster) | The AKS cluster resource. |
| <a name="output_azurerm_postgresql_flexible_server"></a> [azurerm\_postgresql\_flexible\_server](#output\_azurerm\_postgresql\_flexible\_server) | The Flexible Server for PostgreSQL resource. |
| <a name="output_helm_values"></a> [helm\_values](#output\_helm\_values) | The `values.yaml` file for installing Nebuly with Helm.<br/><br/>  The default standard configuration is used, which uses Nginx as ingress controller and exposes the application to the Internet. This configuration can be customized according to specific needs. |
| <a name="output_helm_values_bootstrap"></a> [helm\_values\_bootstrap](#output\_helm\_values\_bootstrap) | The `bootrap.values.yaml` file for installing the Nebuly Azure Boostrap chart with Helm. |
| <a name="output_postgres_server_admin"></a> [postgres\_server\_admin](#output\_postgres\_server\_admin) | The administrator login for the PostgreSQL server. |
| <a name="output_secret_provider_class"></a> [secret\_provider\_class](#output\_secret\_provider\_class) | The `secret-provider-class.yaml` file to make Kubernetes reference the secrets stored in the Key Vault. |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aks_cluster_admin_group_object_ids"></a> [aks\_cluster\_admin\_group\_object\_ids](#input\_aks\_cluster\_admin\_group\_object\_ids) | Object IDs that are granted the Cluster Admin role over the AKS cluster. | `set(string)` | n/a | yes |
| <a name="input_aks_cluster_admin_users"></a> [aks\_cluster\_admin\_users](#input\_aks\_cluster\_admin\_users) | User Principal Names (UPNs) of the users that are granted the Cluster Admin role over the AKS cluster. | `set(string)` | n/a | yes |
| <a name="input_aks_kubernetes_version"></a> [aks\_kubernetes\_version](#input\_aks\_kubernetes\_version) | The Kubernetes version to use. | <pre>object({<br/>    workers       = string<br/>    control_plane = string<br/>  })</pre> | <pre>{<br/>  "control_plane": "1.31.5",<br/>  "workers": "1.31.5"<br/>}</pre> | no |
| <a name="input_aks_log_analytics_solution"></a> [aks\_log\_analytics\_solution](#input\_aks\_log\_analytics\_solution) | Existing azurerm\_log\_analytics\_solution to be attached to the azurerm\_log\_analytics\_workspace. Providing the config disables creation of azurerm\_log\_analytics\_solution. | <pre>object({<br/>    id                  = string<br/>    name                = string<br/>    location            = optional(string)<br/>    resource_group_name = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_aks_log_analytics_workspace"></a> [aks\_log\_analytics\_workspace](#input\_aks\_log\_analytics\_workspace) | Existing azurerm\_log\_analytics\_workspace to attach azurerm\_log\_analytics\_solution. Providing the config disables creation of azurerm\_log\_analytics\_workspace. | <pre>object({<br/>    id                  = string<br/>    name                = string<br/>    location            = optional(string)<br/>    resource_group_name = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_aks_log_analytics_workspace_enabled"></a> [aks\_log\_analytics\_workspace\_enabled](#input\_aks\_log\_analytics\_workspace\_enabled) | Enable the integration of azurerm\_log\_analytics\_workspace and azurerm\_log\_analytics\_solution. | `bool` | `true` | no |
| <a name="input_aks_net_profile_dns_service_ip"></a> [aks\_net\_profile\_dns\_service\_ip](#input\_aks\_net\_profile\_dns\_service\_ip) | IP address within the Kubernetes service address range that is used by cluster service discovery (kube-dns). Must be inluced in net\_profile\_cidr. Example: 10.32.0.10 | `string` | `"10.32.0.10"` | no |
| <a name="input_aks_net_profile_service_cidr"></a> [aks\_net\_profile\_service\_cidr](#input\_aks\_net\_profile\_service\_cidr) | The Network Range used by the Kubernetes service. Must not overlap with the AKS Nodes address space. Example: 10.32.0.0/24 | `string` | `"10.32.0.0/24"` | no |
| <a name="input_aks_network_plugin_mode"></a> [aks\_network\_plugin\_mode](#input\_aks\_network\_plugin\_mode) | Network plugin mode used for building the Kubernetes network. Possible value is `overlay`. | `string` | `null` | no |
| <a name="input_aks_override_name"></a> [aks\_override\_name](#input\_aks\_override\_name) | Override the name of the Azure Kubernetes Service resource. If not provided, the name is generated based on the resource\_prefix. | `string` | `null` | no |
| <a name="input_aks_private_cluster_enabled"></a> [aks\_private\_cluster\_enabled](#input\_aks\_private\_cluster\_enabled) | If true cluster API server will be exposed only on internal IP address and available only in cluster vnet. | `bool` | `false` | no |
| <a name="input_aks_sku_tier"></a> [aks\_sku\_tier](#input\_aks\_sku\_tier) | The AKS tier. Possible values are: Free, Standard, Premium. It is recommended to use Standard or Premium for production workloads. | `string` | `"Standard"` | no |
| <a name="input_aks_sys_pool"></a> [aks\_sys\_pool](#input\_aks\_sys\_pool) | The configuration of the AKS System Nodes Pool. | <pre>object({<br/>    vm_size : string<br/>    nodes_max_pods : number<br/>    name : string<br/>    availability_zones : list(string)<br/>    disk_size_gb : number<br/>    disk_type : string<br/>    nodes_labels : optional(map(string), {})<br/>    nodes_tags : optional(map(string), {})<br/>    only_critical_addons_enabled : optional(bool, false)<br/>    # Auto-scaling settings<br/>    nodes_count : optional(number, null)<br/>    enable_auto_scaling : optional(bool, false)<br/>    agents_min_count : optional(number, null)<br/>    agents_max_count : optional(number, null)<br/>  })</pre> | <pre>{<br/>  "agents_max_count": 1,<br/>  "agents_min_count": 1,<br/>  "availability_zones": [<br/>    "1",<br/>    "2",<br/>    "3"<br/>  ],<br/>  "disk_size_gb": 128,<br/>  "disk_type": "Ephemeral",<br/>  "enable_auto_scaling": true,<br/>  "name": "system",<br/>  "nodes_max_pods": 60,<br/>  "only_critical_addons_enabled": false,<br/>  "vm_size": "Standard_E4ads_v5"<br/>}</pre> | no |
| <a name="input_aks_worker_pools"></a> [aks\_worker\_pools](#input\_aks\_worker\_pools) | The worker pools of the AKS cluster, each with the respective configuration.<br/>  The default configuration uses a single worker node, with no HA. | <pre>map(object({<br/>    enabled : optional(bool, true)<br/>    vm_size : string<br/>    priority : optional(string, "Regular")<br/>    tags : map(string)<br/>    max_pods : number<br/>    disk_size_gb : optional(number, 128)<br/>    disk_type : string<br/>    availability_zones : list(string)<br/>    node_taints : optional(list(string), [])<br/>    node_labels : optional(map(string), {})<br/>    # Auto-scaling settings<br/>    nodes_count : optional(number, null)<br/>    enable_auto_scaling : optional(bool, false)<br/>    nodes_min_count : optional(number, null)<br/>    nodes_max_count : optional(number, null)<br/>  }))</pre> | <pre>{<br/>  "a100wr": {<br/>    "availability_zones": [<br/>      "1",<br/>      "2",<br/>      "3"<br/>    ],<br/>    "disk_size_gb": 128,<br/>    "disk_type": "Ephemeral",<br/>    "enable_auto_scaling": true,<br/>    "max_pods": 30,<br/>    "node_labels": {<br/>      "nebuly.com/accelerator": "nvidia-ampere-a100"<br/>    },<br/>    "node_taints": [<br/>      "nvidia.com/gpu=:NoSchedule"<br/>    ],<br/>    "nodes_count": null,<br/>    "nodes_max_count": 1,<br/>    "nodes_min_count": 0,<br/>    "priority": "Regular",<br/>    "tags": {},<br/>    "vm_size": "Standard_NC24ads_A100_v4"<br/>  }<br/>}</pre> | no |
| <a name="input_azure_openai_deployment_gpt4o"></a> [azure\_openai\_deployment\_gpt4o](#input\_azure\_openai\_deployment\_gpt4o) | ------ Azure OpenAI ------ # | <pre>object({<br/>    name : optional(string, "gpt-4o")<br/>    version : optional(string, "2024-08-06")<br/>    rate_limit : optional(number, 80)<br/>    rai_policy_name : optional(string, "Microsoft.Default")<br/>    enabled : optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_azure_openai_deployment_gpt4o_mini"></a> [azure\_openai\_deployment\_gpt4o\_mini](#input\_azure\_openai\_deployment\_gpt4o\_mini) | n/a | <pre>object({<br/>    name : optional(string, "gpt-4o-mini")<br/>    version : optional(string, "2024-07-18")<br/>    rate_limit : optional(number, 80)<br/>    rai_policy_name : optional(string, "Microsoft.Default")<br/>    enabled : optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_azure_openai_location"></a> [azure\_openai\_location](#input\_azure\_openai\_location) | The Azure region where to deploy the Azure OpenAI models. <br/>  Note that the models required by Nebuly are supported only in few specific regions. For more information, you can refer to Azure documentation:<br/>  https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#standard-deployment-model-availability | `string` | `"EastUS"` | no |
| <a name="input_backups_storage_delete_retention_days"></a> [backups\_storage\_delete\_retention\_days](#input\_backups\_storage\_delete\_retention\_days) | The number of days that backups should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days. | `number` | `7` | no |
| <a name="input_backups_storage_replication_type"></a> [backups\_storage\_replication\_type](#input\_backups\_storage\_replication\_type) | The replication type of the backups storage account. Possible values are: LRS, GRS, RAGRS, ZRS. | `string` | `"GRS"` | no |
| <a name="input_backups_storage_tier_to_cool_after_days_since_creation_greater_than"></a> [backups\_storage\_tier\_to\_cool\_after\_days\_since\_creation\_greater\_than](#input\_backups\_storage\_tier\_to\_cool\_after\_days\_since\_creation\_greater\_than) | The number of days after which to move the backups to the Cool tier. | `number` | `7` | no |
| <a name="input_enable_azuread_application"></a> [enable\_azuread\_application](#input\_enable\_azuread\_application) | If True, creates a dedicated Azure AD application for accessing the provisioned Key Vault. | `bool` | `false` | no |
| <a name="input_enable_azuread_groups"></a> [enable\_azuread\_groups](#input\_enable\_azuread\_groups) | If True, the module will create Azure AD groups for assigning permissions to the resources. | `bool` | `true` | no |
| <a name="input_enable_key_vault_secrets"></a> [enable\_key\_vault\_secrets](#input\_enable\_key\_vault\_secrets) | If True, the module will create secrets in the Key Vault.<br/>  When enabled, the networking must be configured so that Terraform can access the Key Vault over the Private Endpoint. | `bool` | `true` | no |
| <a name="input_enable_service_endpoints"></a> [enable\_service\_endpoints](#input\_enable\_service\_endpoints) | If True, the module will create service endpoints on the speficied networks, and configure network rules. | `bool` | `false` | no |
| <a name="input_enable_storage_containers"></a> [enable\_storage\_containers](#input\_enable\_storage\_containers) | If True, the module will create the required storage containers for the platform.<br/>  When enabled, the networking must be configured so that Terraform can access the Storage Accounts over the Private Endpoint. | `bool` | `true` | no |
| <a name="input_enable_web_routing_addon"></a> [enable\_web\_routing\_addon](#input\_enable\_web\_routing\_addon) | If True, the module will enable the web routing add-on and create a Private DNS Zone for the Ingress Controller, <br/>  using the domain provided as input variable. | `bool` | `false` | no |
| <a name="input_google_sso"></a> [google\_sso](#input\_google\_sso) | Settings for configuring the Google SSO integration. | <pre>object({<br/>    client_id : string<br/>    client_secret : string<br/>    role_mapping : map(string)<br/>  })</pre> | `null` | no |
| <a name="input_k8s_image_pull_secret_name"></a> [k8s\_image\_pull\_secret\_name](#input\_k8s\_image\_pull\_secret\_name) | The name of the Kubernetes Image Pull Secret to use. <br/>  This value will be used to auto-generate the values.yaml file for installing the Nebuly Platform Helm chart. | `string` | `"nebuly-docker-pull"` | no |
| <a name="input_key_vault_override_name"></a> [key\_vault\_override\_name](#input\_key\_vault\_override\_name) | Override the name of the Key Vault. If not provided, the name is generated based on the resource\_prefix. | `string` | `null` | no |
| <a name="input_key_vault_public_network_access_enabled"></a> [key\_vault\_public\_network\_access\_enabled](#input\_key\_vault\_public\_network\_access\_enabled) | Can the Key Vault be accessed from the Internet, according to the firewall rules?<br/>  Default to true to to allow the Terraform module to be executed even outside the private virtual network. <br/>  When set to true, firewall rules are applied, and all connections are denied by default. | `bool` | `true` | no |
| <a name="input_key_vault_purge_protection_enabled"></a> [key\_vault\_purge\_protection\_enabled](#input\_key\_vault\_purge\_protection\_enabled) | Is purge protection enabled for the Key Vault? | `bool` | `false` | no |
| <a name="input_key_vault_sku_name"></a> [key\_vault\_sku\_name](#input\_key\_vault\_sku\_name) | The SKU of the Key Vault. | `string` | `"Standard"` | no |
| <a name="input_key_vault_soft_delete_retention_days"></a> [key\_vault\_soft\_delete\_retention\_days](#input\_key\_vault\_soft\_delete\_retention\_days) | The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days. | `number` | `7` | no |
| <a name="input_location"></a> [location](#input\_location) | The region where to provision the resources. | `string` | n/a | yes |
| <a name="input_nebuly_credentials"></a> [nebuly\_credentials](#input\_nebuly\_credentials) | The credentials provided by Nebuly are required for activating your platform installation. <br/>  If you haven't received your credentials or have lost them, please contact support@nebuly.ai. | <pre>object({<br/>    client_id : string<br/>    client_secret : string<br/>  })</pre> | n/a | yes |
| <a name="input_okta_sso"></a> [okta\_sso](#input\_okta\_sso) | Settings for configuring the Okta SSO integration. | <pre>object({<br/>    issuer : string<br/>    client_id : string<br/>    client_secret : string<br/>  })</pre> | `null` | no |
| <a name="input_platform_domain"></a> [platform\_domain](#input\_platform\_domain) | The domain on which the deployed Nebuly platform is made accessible. | `string` | n/a | yes |
| <a name="input_postgres_override_name"></a> [postgres\_override\_name](#input\_postgres\_override\_name) | Override the name of the PostgreSQL Server. If not provided, the name is generated based on the resource\_prefix. | `string` | `null` | no |
| <a name="input_postgres_server_admin_username"></a> [postgres\_server\_admin\_username](#input\_postgres\_server\_admin\_username) | The username of the admin user of the PostgreSQL Server. | `string` | `"nebulyadmin"` | no |
| <a name="input_postgres_server_alert_rules"></a> [postgres\_server\_alert\_rules](#input\_postgres\_server\_alert\_rules) | The Azure Monitor alert rules to set on the provisioned PostgreSQL server. | <pre>map(object({<br/>    description     = string<br/>    frequency       = string<br/>    window_size     = string<br/>    action_group_id = string<br/>    severity        = number<br/><br/>    criteria = optional(<br/>      object({<br/>        aggregation = string<br/>        metric_name = string<br/>        operator    = string<br/>        threshold   = number<br/>      })<br/>    , null)<br/>    dynamic_criteria = optional(<br/>      object({<br/>        aggregation       = string<br/>        metric_name       = string<br/>        operator          = string<br/>        alert_sensitivity = string<br/>      })<br/>    , null)<br/>  }))</pre> | `{}` | no |
| <a name="input_postgres_server_extra_databases"></a> [postgres\_server\_extra\_databases](#input\_postgres\_server\_extra\_databases) | List of additional databases to create on the PostgreSQL Server. The default database is always created. | <pre>map(object({<br/>    charset : optional(string, "utf8")<br/>    collation : optional(string, "en_US.utf8")<br/>  }))</pre> | `{}` | no |
| <a name="input_postgres_server_high_availability"></a> [postgres\_server\_high\_availability](#input\_postgres\_server\_high\_availability) | High-availability configuration of the DB server. Possible values for mode are: SameZone or ZoneRedundant. | <pre>object({<br/>    enabled : bool<br/>    mode : optional(string, "SameZone")<br/>    standby_availability_zone : optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": true,<br/>  "mode": "SameZone"<br/>}</pre> | no |
| <a name="input_postgres_server_lock"></a> [postgres\_server\_lock](#input\_postgres\_server\_lock) | Optionally lock the PostgreSQL server to prevent deletion. | <pre>object({<br/>    enabled = optional(bool, false)<br/>    notes   = optional(string, "Cannot be deleted.")<br/>    name    = optional(string, "terraform-lock")<br/>  })</pre> | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_postgres_server_maintenance_window"></a> [postgres\_server\_maintenance\_window](#input\_postgres\_server\_maintenance\_window) | The window for performing automatic maintenance of the PostgreSQL Server. Default is Sunday at 00:00 of the timezone of the server location. | <pre>object({<br/>    day_of_week : number<br/>    start_hour : number<br/>    start_minute : number<br/>  })</pre> | <pre>{<br/>  "day_of_week": 0,<br/>  "start_hour": 0,<br/>  "start_minute": 0<br/>}</pre> | no |
| <a name="input_postgres_server_max_storage_mb"></a> [postgres\_server\_max\_storage\_mb](#input\_postgres\_server\_max\_storage\_mb) | The max storage allowed for the PostgreSQL Flexible Server. Possible values are 32768, 65536, 131072, 262144, 524288, 1048576, 2097152, 4193280, 4194304, 8388608, 16777216 and 33553408. | `number` | `262144` | no |
| <a name="input_postgres_server_optional_configurations"></a> [postgres\_server\_optional\_configurations](#input\_postgres\_server\_optional\_configurations) | Optional Flexible PostgreSQL configurations. Defaults to recommended configurations. | `map(string)` | <pre>{<br/>  "intelligent_tuning": "on",<br/>  "intelligent_tuning.metric_targets": "ALL",<br/>  "metrics.autovacuum_diagnostics": "on",<br/>  "metrics.collector_database_activity": "on",<br/>  "pg_qs.query_capture_mode": "ALL",<br/>  "pg_qs.retention_period_in_days": "7",<br/>  "pg_qs.store_query_plans": "on",<br/>  "pgaudit.log": "WRITE",<br/>  "pgms_wait_sampling.query_capture_mode": "ALL",<br/>  "track_io_timing": "on"<br/>}</pre> | no |
| <a name="input_postgres_server_point_in_time_backup"></a> [postgres\_server\_point\_in\_time\_backup](#input\_postgres\_server\_point\_in\_time\_backup) | The backup settings of the PostgreSQL Server. | <pre>object({<br/>    geo_redundant : optional(bool, true)<br/>    retention_days : optional(number, 30)<br/>  })</pre> | <pre>{<br/>  "geo_redundant": true,<br/>  "retention_days": 30<br/>}</pre> | no |
| <a name="input_postgres_server_sku"></a> [postgres\_server\_sku](#input\_postgres\_server\_sku) | The SKU of the PostgreSQL Server, including the Tier and the Name. Examples: B\_Standard\_B1ms, GP\_Standard\_D2s\_v3, MO\_Standard\_E4s\_v3 | <pre>object({<br/>    tier : string<br/>    name : string<br/>  })</pre> | <pre>{<br/>  "name": "Standard_D4ds_v5",<br/>  "tier": "GP"<br/>}</pre> | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | The PostgreSQL version to use. | `string` | `"16"` | no |
| <a name="input_private_dns_zones"></a> [private\_dns\_zones](#input\_private\_dns\_zones) | Private DNS zones to use for Private Endpoint connections. If not provided, a new DNS Zone <br/>  is created and linked to the respective subnet. | <pre>object({<br/>    flexible_postgres = optional(object({<br/>      name : string<br/>      resource_group_name : string<br/>      link_vnet : optional(bool, true)<br/>    }), null)<br/>    openai = optional(object({<br/>      name : string<br/>      resource_group_name : string<br/>      link_vnet : optional(bool, true)<br/>    }), null)<br/>    key_vault = optional(object({<br/>      name : string<br/>      resource_group_name : string<br/>      link_vnet : optional(bool, true)<br/>    }), null)<br/>    blob = optional(object({<br/>      name : string<br/>      resource_group_name : string<br/>      link_vnet : optional(bool, true)<br/>    }), null)<br/>    dfs = optional(object({<br/>      name : string<br/>      resource_group_name : string<br/>      link_vnet : optional(bool, true)<br/>    }), null)<br/>  })</pre> | `{}` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group where to provision the resources. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | The prefix that is used for generating resource names. | `string` | n/a | yes |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | The suffix that is used for generating resource names. | `string` | `null` | no |
| <a name="input_storage_account_override_name"></a> [storage\_account\_override\_name](#input\_storage\_account\_override\_name) | Override the name of the Storage Account. If not provided, the name is generated based on the resource\_prefix. | `string` | `null` | no |
| <a name="input_subnet_address_space_aks_nodes"></a> [subnet\_address\_space\_aks\_nodes](#input\_subnet\_address\_space\_aks\_nodes) | Address space of the new subnet in which to create the nodes of the AKS cluster. <br/>  If `subnet_name_aks_nodes` is provided, the existing subnet is used and this variable is ignored. | `list(string)` | <pre>[<br/>  "10.0.0.0/22"<br/>]</pre> | no |
| <a name="input_subnet_address_space_flexible_postgres"></a> [subnet\_address\_space\_flexible\_postgres](#input\_subnet\_address\_space\_flexible\_postgres) | Address space of the new subnet delgated to Flexible PostgreSQL Server service. <br/>  If `subnet_name_flexible_postgres` is provided, the existing subnet is used and this variable is ignored. | `list(string)` | <pre>[<br/>  "10.0.12.0/26"<br/>]</pre> | no |
| <a name="input_subnet_address_space_private_endpoints"></a> [subnet\_address\_space\_private\_endpoints](#input\_subnet\_address\_space\_private\_endpoints) | Address space of the new subnet in which to create private endpoints. <br/>  If `subnet_name_private_endpoints` is provided, the existing subnet is used and this variable is ignored. | `list(string)` | <pre>[<br/>  "10.0.8.0/26"<br/>]</pre> | no |
| <a name="input_subnet_name_aks_nodes"></a> [subnet\_name\_aks\_nodes](#input\_subnet\_name\_aks\_nodes) | Optional name of the subnet to be used for provisioning AKS nodes.<br/>  If not provided, a new subnet is created. | `string` | `null` | no |
| <a name="input_subnet_name_flexible_postgres"></a> [subnet\_name\_flexible\_postgres](#input\_subnet\_name\_flexible\_postgres) | Optional name of the subnet delegated to Flexible PostgreSQL Server service. <br/>  If not provided, a new subnet is created. | `string` | `null` | no |
| <a name="input_subnet_name_private_endpoints"></a> [subnet\_name\_private\_endpoints](#input\_subnet\_name\_private\_endpoints) | Optional name of the subnet to which attach the Private Endpoints. <br/>  If not provided, a new subnet is created. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags that are applied to all resources. | `map(string)` | `{}` | no |
| <a name="input_virtual_network"></a> [virtual\_network](#input\_virtual\_network) | Optional name of the virtual network in which to create the resources. <br/>  If not provided, a new virtual network is created. | <pre>object({<br/>    name                = string<br/>    resource_group_name = string<br/>  })</pre> | `null` | no |
| <a name="input_virtual_network_address_space"></a> [virtual\_network\_address\_space](#input\_virtual\_network\_address\_space) | Address space of the new virtual network in which to create resources. <br/>  If `virtual_network_name` is provided, the existing virtual network is used and this variable is ignored. | `list(string)` | <pre>[<br/>  "10.0.0.0/16"<br/>]</pre> | no |
| <a name="input_whitelisted_ips"></a> [whitelisted\_ips](#input\_whitelisted\_ips) | Optional list of IPs or IP Ranges that will be able to access the following resources from the internet: Azure Kubernetes Service (AKS) API Server, <br/>  Azure Key Vault, Azure Storage Account. If 0.0.0.0/0 (default value), no whitelisting is enforced and the resources are accessible from all IPs.<br/><br/>  The whitelisting excludes the Database Server, which remains unexposed to the Internet and is accessible only from the virtual network. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |

## Resources


- resource.azuread_application.main (/terraform-docs/main.tf#466)
- resource.azuread_group.aks_admins (/terraform-docs/main.tf#1070)
- resource.azuread_group_member.aks_admin_users (/terraform-docs/main.tf#1080)
- resource.azuread_service_principal.main (/terraform-docs/main.tf#478)
- resource.azuread_service_principal_password.main (/terraform-docs/main.tf#485)
- resource.azurerm_cognitive_account.main (/terraform-docs/main.tf#732)
- resource.azurerm_cognitive_deployment.gpt_4o (/terraform-docs/main.tf#756)
- resource.azurerm_cognitive_deployment.gpt_4o_mini (/terraform-docs/main.tf#773)
- resource.azurerm_key_vault.main (/terraform-docs/main.tf#399)
- resource.azurerm_key_vault_secret.azure_openai_api_key (/terraform-docs/main.tf#790)
- resource.azurerm_key_vault_secret.azuread_application_client_id (/terraform-docs/main.tf#498)
- resource.azurerm_key_vault_secret.azuread_application_client_secret (/terraform-docs/main.tf#513)
- resource.azurerm_key_vault_secret.backups_storage_primary_key (/terraform-docs/main.tf#1050)
- resource.azurerm_key_vault_secret.google_sso_client_id (/terraform-docs/main.tf#1259)
- resource.azurerm_key_vault_secret.google_sso_client_secret (/terraform-docs/main.tf#1270)
- resource.azurerm_key_vault_secret.jwt_signing_key (/terraform-docs/main.tf#1223)
- resource.azurerm_key_vault_secret.nebuly_azure_client_id (/terraform-docs/main.tf#531)
- resource.azurerm_key_vault_secret.nebuly_azure_client_secret (/terraform-docs/main.tf#542)
- resource.azurerm_key_vault_secret.okta_sso_client_id (/terraform-docs/main.tf#1237)
- resource.azurerm_key_vault_secret.okta_sso_client_secret (/terraform-docs/main.tf#1248)
- resource.azurerm_key_vault_secret.postgres_password (/terraform-docs/main.tf#709)
- resource.azurerm_key_vault_secret.postgres_user (/terraform-docs/main.tf#698)
- resource.azurerm_kubernetes_cluster_node_pool.linux_pools (/terraform-docs/main.tf#1180)
- resource.azurerm_management_lock.postgres_server (/terraform-docs/main.tf#641)
- resource.azurerm_monitor_metric_alert.postgres_server_alerts (/terraform-docs/main.tf#649)
- resource.azurerm_postgresql_flexible_server.main (/terraform-docs/main.tf#563)
- resource.azurerm_postgresql_flexible_server_configuration.mandatory_configurations (/terraform-docs/main.tf#614)
- resource.azurerm_postgresql_flexible_server_configuration.optional_configurations (/terraform-docs/main.tf#607)
- resource.azurerm_postgresql_flexible_server_database.analytics (/terraform-docs/main.tf#635)
- resource.azurerm_postgresql_flexible_server_database.auth (/terraform-docs/main.tf#629)
- resource.azurerm_postgresql_flexible_server_database.extras (/terraform-docs/main.tf#621)
- resource.azurerm_private_dns_zone.blob (/terraform-docs/main.tf#313)
- resource.azurerm_private_dns_zone.dfs (/terraform-docs/main.tf#331)
- resource.azurerm_private_dns_zone.flexible_postgres (/terraform-docs/main.tf#276)
- resource.azurerm_private_dns_zone.key_vault (/terraform-docs/main.tf#295)
- resource.azurerm_private_dns_zone.openai (/terraform-docs/main.tf#349)
- resource.azurerm_private_dns_zone.web_app_routing (/terraform-docs/main.tf#367)
- resource.azurerm_private_dns_zone_virtual_network_link.blob (/terraform-docs/main.tf#318)
- resource.azurerm_private_dns_zone_virtual_network_link.dfs (/terraform-docs/main.tf#336)
- resource.azurerm_private_dns_zone_virtual_network_link.flexible_postgres (/terraform-docs/main.tf#282)
- resource.azurerm_private_dns_zone_virtual_network_link.key_vault (/terraform-docs/main.tf#300)
- resource.azurerm_private_dns_zone_virtual_network_link.openai (/terraform-docs/main.tf#354)
- resource.azurerm_private_dns_zone_virtual_network_link.web_app_routing (/terraform-docs/main.tf#378)
- resource.azurerm_private_endpoint.backups_blob (/terraform-docs/main.tf#969)
- resource.azurerm_private_endpoint.backups_dfs (/terraform-docs/main.tf#992)
- resource.azurerm_private_endpoint.key_vault (/terraform-docs/main.tf#425)
- resource.azurerm_private_endpoint.models_blob (/terraform-docs/main.tf#875)
- resource.azurerm_private_endpoint.models_dfs (/terraform-docs/main.tf#898)
- resource.azurerm_private_endpoint.openai (/terraform-docs/main.tf#801)
- resource.azurerm_role_assignment.aks_network_contributor (/terraform-docs/main.tf#1175)
- resource.azurerm_role_assignment.key_vault_secret_officer__current (/terraform-docs/main.tf#456)
- resource.azurerm_role_assignment.key_vault_secret_user__aks (/terraform-docs/main.tf#448)
- resource.azurerm_role_assignment.nebuly_secrets_officer (/terraform-docs/main.tf#491)
- resource.azurerm_role_assignment.storage_container_models__data_contributor (/terraform-docs/main.tf#868)
- resource.azurerm_role_assignment.web_app_routing_identity__dns_zone (/terraform-docs/main.tf#390)
- resource.azurerm_storage_account.backups (/terraform-docs/main.tf#933)
- resource.azurerm_storage_account.main (/terraform-docs/main.tf#839)
- resource.azurerm_storage_container.clickhouse (/terraform-docs/main.tf#963)
- resource.azurerm_storage_container.models (/terraform-docs/main.tf#862)
- resource.azurerm_storage_management_policy.backups (/terraform-docs/main.tf#1015)
- resource.azurerm_subnet.aks_nodes (/terraform-docs/main.tf#200)
- resource.azurerm_subnet.flexible_postgres (/terraform-docs/main.tf#224)
- resource.azurerm_subnet.private_endpoints (/terraform-docs/main.tf#216)
- resource.azurerm_virtual_network.main (/terraform-docs/main.tf#188)
- resource.random_password.postgres_server_admin_password (/terraform-docs/main.tf#558)
- resource.time_sleep.wait_aks_creation (/terraform-docs/main.tf#1162)
- resource.tls_private_key.aks (/terraform-docs/main.tf#1066)
- resource.tls_private_key.jwt_signing_key (/terraform-docs/main.tf#1219)
- data source.azuread_user.aks_admins (/terraform-docs/main.tf#108)
- data source.azurerm_client_config.current (/terraform-docs/main.tf#100)
- data source.azurerm_private_dns_zone.blob (/terraform-docs/main.tf#173)
- data source.azurerm_private_dns_zone.dfs (/terraform-docs/main.tf#179)
- data source.azurerm_private_dns_zone.flexible_postgres (/terraform-docs/main.tf#155)
- data source.azurerm_private_dns_zone.key_vault (/terraform-docs/main.tf#167)
- data source.azurerm_private_dns_zone.openai (/terraform-docs/main.tf#161)
- data source.azurerm_resource_group.main (/terraform-docs/main.tf#97)
- data source.azurerm_subnet.aks_nodes (/terraform-docs/main.tf#113)
- data source.azurerm_subnet.flexible_postgres (/terraform-docs/main.tf#141)
- data source.azurerm_subnet.private_endpoints (/terraform-docs/main.tf#127)
- data source.azurerm_virtual_network.main (/terraform-docs/main.tf#102)
