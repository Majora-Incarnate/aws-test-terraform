# Meant to allow standing up isolated stacks, not implemented
variable "environment" {
  default = "dev"
}
variable "tenant" {
  default = "default"
}

# Resource configuration variables
variable "elasticsearch_domain" {
  default = "default"
}
variable "elasticsearch_version" {
  default = "6.7"
}
variable "elasticsearch_flavor" {
  default = "t2.small.elasticsearch"
}

# AWS Related Vars
variable "aws_region" {
  default = "us-east-2"
}
variable "aws_s3_bucket" {
  default = "trevin-terraform-state"
}
variable "aws_access_key" {}
variable "aws_secret_key" {}
