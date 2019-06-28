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

resource "aws_security_group" "elasticsearch" {
  name        = "vpc-elasticsearch-${var.elasticsearch_domain}"
  vpc_id       = data.terraform_remote_state.infra.outputs.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "${data.terraform_remote_state.infra.outputs.vpc_cidr}",
    ]
  }
}

// I saw this in the vpc example for the elasticsearch setup, but not sure if it is actually necessary?
resource "aws_iam_service_linked_role" "elasticsearch" {
  aws_service_name = "es.amazonaws.com"
}

# Create an Elasticsearch cluster
resource "aws_elasticsearch_domain" "domain" {
  domain_name           = var.elasticsearch_domain
  elasticsearch_version = var.elasticsearch_version

  ebs_options {
    ebs_enabled = true
    volume_size = 20
  }

  cluster_config {
    instance_type = var.elasticsearch_flavor
  }

  vpc_options {
    subnet_ids = [data.terraform_remote_state.infra.outputs.es_subnet_ids[0]]

    security_group_ids = ["${aws_security_group.elasticsearch.id}"]
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags = local.tags

  depends_on = [
    "aws_iam_service_linked_role.elasticsearch",
  ]
}
