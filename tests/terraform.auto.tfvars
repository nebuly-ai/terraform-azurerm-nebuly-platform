### General ###
region          = "us-east-1"
resource_prefix = "nbllab"
tags = {
  "env" : "dev"
  "project" : "self-deploy"
}


### EKS ###
eks_kubernetes_version             = "1.28"
eks_cluster_endpoint_public_access = true

### External secrets ###
openai_api_key = "my-key"
