provider "aws" {
    region = "eu-west-1"

}

terraform {
    backend "s3" {
        bucket = "customer-terraform-state-file"
        key = "prod/vpc/terraform.tfstate"
        region = "eu-west-1"

        dynamodb_table = "customer-terraform-locks"
        encrypt = true


    }

}

module "environment_vpc" {
    source ="../../modules/vpc"

    vpc_name = "prod"
    vpc_cidr = "10.1.0.0/16"

    deployment_azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    public_subnet = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
    private_subnet = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]

    require_nat_gateway = true

}