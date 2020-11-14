variable "vpc_name" {
  description = "VPC Name"
  type        = string
}

variable "vpc_cidr" {

  description = "VPC CIDR"
  type        = string

}

variable "deployment_azs" {
  description = "List of AZs in region"
  type        = list
}

variable "public_subnet" {
  description = "List of Private Subnets"
  type        = list
}

variable "private_subnet" {
  description = "List of Private Subnets"
  type        = list
}

variable "require_nat_gateway" {
  description = "NAT Gateway Required"
  type        = bool
}

variable "require_nat_gateway_instance" {
  description = "NAT Gateway Instance Required"
  type        = bool
}

