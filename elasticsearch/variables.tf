variable "environment" {
  default = "dev"
}
variable "tenant" {
  default = "default"
}
variable "es_domain" {
  default = "default"
}
variable "aws_region" {
  default = "us-east-2"
}
variable "aws_s3_bucket" {
  default = "trevin-terraform-state"
}
variable "aws_access_key" {}
variable "aws_secret_key" {}
