#!/bin/bash
# Helps not have to specify this every time
AWS_ACCESS_SECRET=$(grep aws_secret_key terraform.tfvars | grep -o '".*"' | sed 's/"//g')

terraform get -update
terraform init \
-backend-config="secret_key=$AWS_ACCESS_SECRET"
