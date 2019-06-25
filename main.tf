# terraform {
#   backend "s3" {
#     bucket = "trevin-terraform-state"
#     key    = "test/tf.state"
#     region = "us-east-1"
#   }
# }

provider "aws" {
  version = "~> 2.0"
  region  = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

# Create a VPC
# resource "aws_vpc" "vpc" {
#   cidr_block = "10.0.0.0/16"
# }

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  elasticache_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Owner = "user"
    Terraform = "true"
    Environment = "dev"
  }

  vpc_tags = {
    Name = "vpc-name"
  }
}

# data "aws_subnet_ids" "es_subnets" {
#   vpc_id = "${aws_vpc.vpc.id}"
# }

# data "aws_caller_identity" "current" {}

# resource "aws_security_group" "es" {
#   name        = "vpc-elasticsearch-${var.es_domain}"
#   description = "Managed by Terraform"
#   vpc_id      = "${aws_vpc.vpc.id}"

#   ingress {
#     from_port = 443
#     to_port   = 443
#     protocol  = "tcp"

#     cidr_blocks = [
#       "${aws_vpc.vpc.cidr_block}",
#     ]
#   }
# }

# resource "aws_iam_service_linked_role" "es" {
#   aws_service_name = "es.amazonaws.com"
# }

# # Create an Elasticsearch cluster
# resource "aws_elasticsearch_domain" "example" {
#   domain_name           = "${var.domain}"
#   elasticsearch_version = "6.3"

#   cluster_config {
#     instance_type = "m4.large.elasticsearch"
#   }

#   vpc_options {
#     subnet_ids = [
#       "${data.aws_subnet_ids.es_subnets.ids[0]}",
#       "${data.aws_subnet_ids.es_subnets.ids[1]}",
#     ]

#     security_group_ids = ["${aws_security_group.elasticsearch.id}"]
#   }

#   advanced_options = {
#     "rest.action.multi.allow_explicit_index" = "true"
#   }

#   access_policies = <<CONFIG
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Action": "es:*",
#             "Principal": "*",
#             "Effect": "Allow",
#             "Resource": "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.es_domain}/*"
#         }
#     ]
# }
# CONFIG

#   snapshot_options {
#     automated_snapshot_start_hour = 23
#   }

#   tags {
#     Domain = "TestDomain"
#   }

#   depends_on = [
#     "aws_iam_service_linked_role.es",
#   ]
# }


# module "my-cluster" {
#   source       = "terraform-aws-modules/eks/aws"
#   cluster_name = "my-cluster"
#   subnets      = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
#   vpc_id       = "${aws_vpc.vpc.vpc_id}"

#   worker_groups = [
#     {
#       instance_type = "m4.medium"
#       asg_max_size  = 3
#       tags = {
#         key                 = "foo"
#         value               = "bar"
#         propagate_at_launch = true
#       }
#     }
#   ]

#   tags = {
#     environment = "${stack_id}"
#   }
# }

# output "endpoint" {
#   value = "${aws_eks_cluster.example.endpoint}"
# }

# output "kubeconfig-certificate-authority-data" {
#   value = "${aws_eks_cluster.example.certificate_authority.0.data}"
# }


# data "aws_caller_identity" "current" {}

# resource "aws_cloudtrail" "foobar" {
#   name                          = "tf-trail-foobar"
#   s3_bucket_name                = "${aws_s3_bucket.foo.id}"
#   s3_key_prefix                 = "prefix"
#   include_global_service_events = false
# }

# resource "aws_s3_bucket" "foo" {
#   bucket        = "tf-test-trail"
#   force_destroy = true

#   policy = <<POLICY
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "AWSCloudTrailAclCheck",
#             "Effect": "Allow",
#             "Principal": {
#               "Service": "cloudtrail.amazonaws.com"
#             },
#             "Action": "s3:GetBucketAcl",
#             "Resource": "arn:aws:s3:::tf-test-trail"
#         },
#         {
#             "Sid": "AWSCloudTrailWrite",
#             "Effect": "Allow",
#             "Principal": {
#               "Service": "cloudtrail.amazonaws.com"
#             },
#             "Action": "s3:PutObject",
#             "Resource": "arn:aws:s3:::tf-test-trail/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
#             "Condition": {
#                 "StringEquals": {
#                     "s3:x-amz-acl": "bucket-owner-full-control"
#                 }
#             }
#         }
#     ]
# }
# POLICY
# }
