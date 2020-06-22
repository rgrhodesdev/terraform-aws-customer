provider "aws" {
    region = "eu-west-1"
}

terraform {
    required_version = ">= 0.12.0"
    backend "s3" {
        bucket = "customer-terraform-state-file"
        key = "prod/services/webserver-cluster/terraform.tfstate"
        region = "eu-west-1"

        dynamodb_table = "customer-terraform-locks"
        encrypt = true


    }

}

module "webserver-cluster" {

    source ="../../../modules/services/webserver-cluster"

    vpc_remote_state_bucket = "customer-terraform-state-file"
    vpc_remote_state_key = "prod/vpc/terraform.tfstate"

    dns_remote_state_bucket = "customer-terraform-state-file"
    dns_remote_state_key = "global/dns/terraform.tfstate"

    certificates_remote_state_bucket = "customer-terraform-state-file"
    certificates_remote_state_key = "global/certificates/terraform.tfstate"

    cluster_name = "webserver"

    environment = "prod"

    http_alb_port = 80
    https_alb_port = 443

    server_port = 80

    web_ami_id = "ami-0ea3405d2d2522162"
    web_instance_type = "t2.micro"

    web_asg_min = 2
    web_asg_max = 3

}