# Nebuly Platform (Azure)

Terraform module for provisioning Nebuly Platform resources on Microsoft Azure.

Available on [Terraform Registry](https://registry.terraform.io/modules/nebuly-ai/nebuly-platform/azurerm/latest).

## Examples

### Basic usage
```hcl

```





## Providers

No providers.


## Outputs

No outputs.


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | The region where to provision the resources. | `string` | n/a | yes |
| <a name="input_openai_api_key"></a> [openai\_api\_key](#input\_openai\_api\_key) | The API Key used for authenticating with OpenAI. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | The prefix that will be used for generating resource names. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags that will be applied to all resources. | `map(string)` | `{}` | no |

## Resources


