# Use this to allow "namespacing" instances of everything in main.tf
variable "stack_id" {
  default = "default"
}
variable "es_domain" {
    default = "default"
}
variable "aws_region" {
  default = "us-east-1"
}
variable "aws_access_key" {}
variable "aws_secret_key" {}
