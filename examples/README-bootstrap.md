# Bootstrap guide

Complete these steps **before** `terraform apply`. This module does not create the platform resource group, the Terraform state backend, or Nebuly credentials.

The module is consumed from **your** root module (see [basic](./basic), [Okta SSO](./okta-sso), [Google SSO](./google-sso)). Backends are configured in that root module, not inside this repository.

After apply, continue with the install steps in the [module README](../README.md#quickstart) (AKS credentials, image pull secret, Helm charts, DNS).

## 1. Tooling

Install these on the machine or pipeline that will apply:

| Tool | When you need it | Install |
|------|------------------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/install) **>= 1.9** | `terraform init` / `plan` / `apply` | [Install Terraform](https://developer.hashicorp.com/terraform/install) |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) | Auth, resource group, state storage, AKS credentials | [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) | After apply: connect to AKS, apply manifests | [Install kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) |
| [Helm](https://helm.sh/docs/intro/install/) | After apply: bootstrap and platform charts | [Install Helm](https://helm.sh/docs/intro/install/) |

Helm and kubectl are needed **after** apply, not for the Terraform module itself.

**macOS (Homebrew):**

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew install azure-cli kubectl helm
```

**Linux / Windows:** follow the official install pages linked above. On Ubuntu/Debian you can also use Microsoft's Azure CLI packages and HashiCorp's Terraform APT/YUM repos.

Confirm versions:

```bash
terraform version   # must be >= 1.9
az version
kubectl version --client
helm version
```

Authenticate with `az login`, or use a service principal (`client_id` / `client_secret` / `tenant_id` / `subscription_id` as in [basic](./basic)).

## 2. Get Nebuly credentials

Ask Nebuly for `nebuly_credentials` (`client_id` and `client_secret`). These activate the platform installation.

If you do not have them, contact [support@nebuly.ai](mailto:support@nebuly.ai).

## 3. Confirm Azure subscription and quotas

In the target subscription and region (`location`):

- **Standard NCADS_A100_v4 Family vCPUs**: at least **24** (the default worker pool is `Standard_NC24ads_A100_v4`)
- **Azure OpenAI gpt-5.6-sol, gpt-5.6-terra, gpt-5.6-luna**: at least **100k tokens per minute** each (when `enable_azure_openai` is `true`, the default)

Register these resource providers if they are not already registered:

- `Microsoft.ContainerService`
- `Microsoft.DBforPostgreSQL`
- `Microsoft.KeyVault`
- `Microsoft.Storage`
- `Microsoft.CognitiveServices`
- `Microsoft.Network`
- `Microsoft.ManagedIdentity`
- `Microsoft.OperationalInsights`

## 4. Identity and permissions

The identity that runs Terraform (user or service principal) needs:

- **On the platform resource group (or subscription):** `Owner`, or `Contributor` **plus** `User Access Administrator`. The module creates role assignments on Key Vault, Storage, and the AKS/VNet.
- **In Microsoft Entra ID** (with defaults):
  - Permission to **read users**
  - Permission to **create groups**
  - Permission to **create an app registration**

If you cannot create Entra groups, set `enable_azuread_groups = false` and pass existing group object IDs.

## 5. Create the platform resource group

The module does **not** create the resource group. It looks up `resource_group_name` as a data source.

Create it first, in the same region you will pass as `location`:

```bash
az group create -n rg-nebuly-prod -l eastus
```

## 6. Create remote Terraform state

Use remote state. Do not keep `terraform.tfstate` on a laptop or commit it to git.

Losing the state file also means you can no longer safely update or destroy the platform.

**Recommended:** Azure Storage (`azurerm` backend) in a dedicated resource group that is **not** the Nebuly platform resource group. If you destroy or recreate the platform RG, state must survive.

If you already use HCP Terraform, Terraform Enterprise, or another standard remote backend, use that instead.

### Bootstrap the storage account (once)

```bash
az group create -n rg-tfstate -l eastus

az storage account create \
  -n <your-unique-tfstate-account> \
  -g rg-tfstate \
  -l eastus \
  --sku Standard_GRS \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

az storage container create \
  --account-name <your-unique-tfstate-account> \
  --name nebuly-platform-prod \
  --auth-mode login
```

Then harden the account:

- Enable **blob versioning** and **soft delete** (recover a bad apply or accidental delete)
- Keep **encryption** at rest (platform default is fine; use a customer-managed key if policy requires it)
- Grant **RBAC**, not shared keys: `Storage Blob Data Contributor` for the identity that runs Terraform
- Restrict network access if required (same VNet / private-endpoint constraints as the rest of the platform)

### Configure the backend in your root module

```hcl
terraform {
  required_version = ">= 1.9"

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "<your-unique-tfstate-account>"
    container_name       = "nebuly-platform-prod"
    key                  = "terraform.tfstate"

    use_azuread_auth = true
  }
}
```

`use_azuread_auth = true` is the better default. Storage-account keys work, but they are another secret to rotate and protect.

Use **one state file per environment**. Never share production and staging state:

| Environment | Container (or key) |
|-------------|--------------------|
| prod        | `nebuly-platform-prod` / `terraform.tfstate` |
| staging     | `nebuly-platform-staging` / `terraform.tfstate` |

The same storage account is fine; separate containers (or keys) are required.

### Do not

- Use local state on a laptop
- Commit `terraform.tfstate` or `*.tfstate.backup` to git
- Put the state account inside the Nebuly platform resource group
- Share one state key across environments
- Run concurrent `terraform apply` from two machines (blob lease locking helps; still use a single pipeline)
- Share the state file, Helm values dumps, or sensitive `terraform output` values over email or chat

CI/CD must use the same backend and the same Entra identity. Do not keep divergent local copies.

## 7. Decide networking

**Default (simplest):** let the module create the virtual network and subnets. Set `location`, `resource_prefix`, and optionally `virtual_network_address_space` if `10.0.0.0/16` conflicts with existin g networks.

**Existing VNet:** the VNet and these subnets must already exist, with enough address space:

- AKS nodes (`subnet_name_aks_nodes`)
- Private endpoints (`subnet_name_private_endpoints`)
- PostgreSQL delegated subnet (`subnet_name_flexible_postgres`)

Pass them with `virtual_network` and the three `subnet_name_*` variables. PostgreSQL stays private and is never exposed to the internet.

Also decide **where Terraform runs**. Defaults allow Key Vault and Storage public access with firewall rules so apply can run from a workstation. In a locked-down network, Terraform must run from inside the VNet (or you disable `enable_key_vault_secrets` / `enable_storage_containers` and create those objects yourself).

## 8. Collect required inputs

These have no defaults:

| Input | What you need |
|-------|----------------|
| `location` | Azure region |
| `resource_group_name` | Existing resource group from step 5 |
| `resource_prefix` | Short prefix for resource names (storage accounts are globally unique) |
| `platform_domain` | DNS name you will later point at the load balancer, e.g. `nebuly.contoso.com` |
| `nebuly_credentials` | From Nebuly (step 2) |
| `aks_cluster_admin_group_object_ids` | Entra **group** object IDs that should be AKS cluster admin |
| `aks_cluster_admin_users` | User UPNs (emails) that should be AKS cluster admin; can be `[]` if groups are enough |

`platform_domain` is used later for the DNS A record. You do not need the record yet, but you must own the zone and agree the name now (SSO redirect URIs depend on it).

## 9. Optional features (prepare before apply if needed on day one)

**SSO**

- Okta: create the OIDC web app with redirect URI `https://<platform_domain>/backend/auth/oauth/okta/callback`. See [okta-sso](./okta-sso).
- Google: OAuth web client, Cloud Identity API, and groups mapped to admin/member/viewer. See [google-sso](./google-sso).

**Bring-your-own OpenAI**

- Set `enable_azure_openai = false` and provide `openai_api_key`

**Private / locked-down install**

- Existing VNet and subnets, `whitelisted_ips`, optionally `aks_private_cluster_enabled`, and a runner that can reach private endpoints

## 10. Write the root module, then apply

Copy an example, add the `backend "azurerm"` block from step 6, fill in the required variables, then:

```bash
terraform init
terraform plan
terraform apply
```

Then follow the [module README quickstart](../README.md#quickstart) from step 2 (connect to AKS, image pull secret, bootstrap chart, Secret Provider Class, platform chart, DNS A record).
