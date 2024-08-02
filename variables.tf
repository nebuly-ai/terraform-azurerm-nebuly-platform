### General ###
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


### External credentials ###
variable "openai_api_key" {
  description = "The API Key used for authenticating with OpenAI."
  type        = string
}

