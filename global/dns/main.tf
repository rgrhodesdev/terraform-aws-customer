provider "aws" {
    region = "eu-west-1"
}

terraform {
    backend "s3" {
        bucket = "customer-terraform-state-file"
        key = "global/dns/terraform.tfstate"
        region = "eu-west-1"

        dynamodb_table = "customer-terraform-locks"
        encrypt = true

    }

}

resource "aws_route53_zone" "public" {
  name = "rgrhodesdev.co.uk"
}