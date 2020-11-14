provider "aws" {
    region = "eu-west-1"

}

terraform {
    required_version = ">= 0.12.0"
    backend "s3" {
        bucket = "customer-terraform-state-file"
        key = "stage/vpc/terraform.tfstate"
        region = "eu-west-1"

        dynamodb_table = "customer-terraform-locks"
        encrypt = true


    }

}

module "environment_vpc" {
    source ="../../modules/vpc"

    vpc_name = "stage"
    vpc_cidr = "10.0.0.0/16"

    deployment_azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
    public_subnet = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnet = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

    require_nat_gateway = false
    require_nat_gateway_instance = false

}