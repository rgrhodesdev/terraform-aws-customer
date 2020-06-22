output "vpc_id" {
  value       = aws_vpc.customer_vpc.id
  description = "VPC ID"

}

output "public_subnet_ids" {
  value       = aws_subnet.customer_public_subnet.*.id
  description = "Public Subnet IDs"

}

output "private_subnet_ids" {
  value       = aws_subnet.customer_private_subnet.*.id
  description = "Private Subnet IDs"

}
