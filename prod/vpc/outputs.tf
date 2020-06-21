output "vpc_id" {
    value = module.environment_vpc.vpc_id
    description = "VPC ID"

}

output "public_subnet_ids" {
    value = module.environment_vpc.public_subnet_ids
    description = "Public Subnet IDs"

}

output "private_subnet_ids" {
    value = module.environment_vpc.private_subnet_ids
    description = "Private Subnet IDs"

}