# VPC Module deploys the following infrastructure
# VPC with defined CIDR
# Internet Gateway to route public subnets directly to the internet
# NAT Gateway (optional) to route private subnets out to the internet
# Public and Private subnets deployed across region AZs
# Public and Private route tables and default rules
# Route table association with public and private subnets

# Create VPC with defined CIDR

resource "aws_vpc" "customer_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

# Create IGW

resource "aws_internet_gateway" "customer_igw" {
  vpc_id = aws_vpc.customer_vpc.id

}

# If require_nat_gateway variable is true then create EIP and NAT Gateway
# Create EIP for NAT Gateway (optional)

resource "aws_eip" "nat" {
  count = var.require_nat_gateway ? 1 : 0

  vpc        = true
  depends_on = [aws_internet_gateway.customer_igw]
}

# Create NAT Gateway (optional)
# Attach EIP and deploy to public subnet (AZa)

resource "aws_nat_gateway" "customer_ngw" {
  count = var.require_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.customer_public_subnet[0].id
}

# Create public subnets

resource "aws_subnet" "customer_public_subnet" {
  count             = length(var.public_subnet)
  vpc_id            = aws_vpc.customer_vpc.id
  cidr_block        = var.public_subnet[count.index]
  availability_zone = var.deployment_azs[count.index]

  tags = {

    Name = "${var.vpc_name} public subnet ${count.index + 1}"
  }
}

# Create Private subnets

resource "aws_subnet" "customer_private_subnet" {
  count             = length(var.private_subnet)
  vpc_id            = aws_vpc.customer_vpc.id
  cidr_block        = var.private_subnet[count.index]
  availability_zone = var.deployment_azs[count.index]

  tags = {

    Name = "${var.vpc_name} private subnet ${count.index + 1}"
  }
}

# Create Public Route Table

resource "aws_route_table" "customer_public_rt" {
  #count                   = length(var.public_subnet)
  vpc_id = aws_vpc.customer_vpc.id

  tags = {
    #Name = "${var.vpc_name} public RT ${count.index+1}"
    Name = "${var.vpc_name} public RT"
  }

}

# Create Private Route Table

resource "aws_route_table" "customer_private_rt" {

  vpc_id = aws_vpc.customer_vpc.id

  tags = {
    Name = "${var.vpc_name} private RT"
  }

}

# Associate all public subnets with the public route table

resource "aws_route_table_association" "customer_public_rt_assoc" {
  count = length(var.public_subnet)

  route_table_id = aws_route_table.customer_public_rt.id
  subnet_id      = aws_subnet.customer_public_subnet[count.index].id

}

# Associate all private subnets with the private route table

resource "aws_route_table_association" "customer_private_rt_assoc" {
  count = length(var.private_subnet)

  route_table_id = aws_route_table.customer_private_rt.id
  subnet_id      = aws_subnet.customer_private_subnet[count.index].id

}

# Public Route Table Rules For all public subnets

resource "aws_route" "customer_public_rt_default_route" {
  route_table_id         = aws_route_table.customer_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.customer_igw.id
}

# Private Route Table Rules For all private subnets

# The following default rule to the NAT gatway will only be created if require_nat_gateway = true

resource "aws_route" "customer_private_rt_a_default_route" {
  count = var.require_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.customer_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.customer_ngw[count.index].id
}
