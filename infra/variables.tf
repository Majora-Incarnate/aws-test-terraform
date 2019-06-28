# Meant to allow standing up isolated stacks, not implemented
variable "environment" {
  default = "dev"
}
variable "tenant" {
  default = "default"
}

# Resource configuration variables
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "azs" {
  default = []
}
variable "aws_es_subnets" {
  default = []
}
variable "aws_eks_subnets" {
  default = []
}
variable "aws_public_subnets" {
  default = []
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
