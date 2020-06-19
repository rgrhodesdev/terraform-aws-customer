provider "aws" {
    region = "eu-west-1"

}

terraform {
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

    vpc_name = "staging"
    vpc_cidr = "192.168.0.0/16"

    public_subnet_a = "192.168.1.0/24"
    public_subnet_b = "192.168.2.0/24"
    public_subnet_c = "192.168.3.0/24"

    private_subnet_a = "192.168.10.0/24"
    private_subnet_b = "192.168.11.0/24"
    private_subnet_c = "192.168.12.0/24"

    require_nat_gateway = false

}