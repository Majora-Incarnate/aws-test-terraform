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

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = var.vpc_cidr

  azs                 = var.azs
  elasticache_subnets = var.aws_es_subnets
  private_subnets     = var.aws_eks_subnets
  public_subnets      = var.aws_public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags

  vpc_tags = local.tags
}
