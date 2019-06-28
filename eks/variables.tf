# Meant to allow standing up isolated stacks, not implemented
variable "environment" {
  default = "dev"
}
variable "tenant" {
  default = "default"
}

# Resource configuration variables
variable "worker_flavor" {
  default = "t2.small"
}
variable "worker_desired_capacity" {
  default = 3
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
