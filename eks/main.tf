terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = "~> 2.7.0"
  region  = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Use this to standardize any sort of metadata across modules/resources
locals {
  tags = {
    Owner = "Trevin Teacutter"
    Terraform = "true"
    Environment = var.environment
    Tenant = var.tenant
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    bucket     = var.aws_s3_bucket
    key        = "infra/terraform.tfstate"
    region     = var.aws_region
    encrypt    = true
  }
}

module "eks-cluster" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = "${var.environment}-${var.tenant}"
  subnets      = data.terraform_remote_state.infra.outputs.eks_subnet_ids
  vpc_id       = data.terraform_remote_state.infra.outputs.vpc_id

  worker_groups = [
    {
      instance_type = var.worker_flavor
      asg_max_size  = var.worker_asg_max_size
      tags = local.tags
    }
  ]

  tags = local.tags
}