terraform {
  backend "s3" {
    key            = "elasticsearch/terraform.tfstate"
    bucket         = "trevin-terraform-state"
    region         = "us-east-2"
    encrypt        = true
    access_key     = "AKIARDZHDV24FIQEDXEI"
    dynamodb_table = "terraform-state-lock"
  }
}