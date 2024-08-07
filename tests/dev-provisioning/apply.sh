#!/bin/bash

if [ "$1" == 'init' ]
  then
    terraform init --backend-config backend.tfvars
    shift 
fi

terraform apply --var-file backend.tfvars "$@"
