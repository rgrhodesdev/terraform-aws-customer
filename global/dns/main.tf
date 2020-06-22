# Create Route53 hosted zone

provider "aws" {
  region = "eu-west-1"
}

terraform {
  required_version = ">= 0.12.0"
  backend "s3" {
    bucket = "customer-terraform-state-file"
    key    = "global/dns/terraform.tfstate"
    region = "eu-west-1"

    dynamodb_table = "customer-terraform-locks"
    encrypt        = true

  }

}

resource "aws_route53_zone" "public" {
  name = "rgrhodesdev.co.uk"
}