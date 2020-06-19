resource "aws_vpc" "customer_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
      Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "customer_igw" {
    vpc_id = aws_vpc.customer_vpc.id
  
}

resource "aws_eip" "nat" {
    count = var.require_nat_gateway ? 1 : 0

    vpc      = true
    depends_on = [aws_internet_gateway.customer_igw]
}

resource "aws_nat_gateway" "customer_ngw" {
    count = var.require_nat_gateway ? 1 : 0

    allocation_id = aws_eip.nat.*.id[count.index]
    subnet_id     = aws_subnet.publica.id
}

resource "aws_subnet" "publica" {
    vpc_id = aws_vpc.customer_vpc.id
    cidr_block = var.public_subnet_a
    availability_zone = "eu-west-1a"

    tags = {
        Name = "${var.vpc_name} public subnet A"
    }

}

resource "aws_subnet" "publicb" {
    vpc_id = aws_vpc.customer_vpc.id
    cidr_block = var.public_subnet_b
    availability_zone = "eu-west-1b"

    tags = {
        Name = "${var.vpc_name} public subnet B"
    }

}

resource "aws_subnet" "publicc" {
    vpc_id = aws_vpc.customer_vpc.id
    cidr_block = var.public_subnet_c
    availability_zone = "eu-west-1c"

    tags = {
        Name = "${var.vpc_name} public subnet C"
    }

}

resource "aws_subnet" "privatea" {
    vpc_id = aws_vpc.customer_vpc.id
    cidr_block = var.private_subnet_a
    availability_zone = "eu-west-1a"

    tags = {

        Name = "${var.vpc_name} private subnet A"
    }

}

resource "aws_subnet" "privateb" {
    vpc_id = aws_vpc.customer_vpc.id
    cidr_block = var.private_subnet_b
    availability_zone = "eu-west-1b"

    tags = {

        Name = "${var.vpc_name} private subnet B"
    }

}

resource "aws_subnet" "privatec" {
    vpc_id = aws_vpc.customer_vpc.id
    cidr_block = var.private_subnet_c
    availability_zone = "eu-west-1c"

    tags = {

        Name = "${var.vpc_name} private subnet C"
    }

}


// Public Route Table A

resource "aws_route_table" "customer_public_a_rt" {

    vpc_id = aws_vpc.customer_vpc.id   

    tags = {
        Name = "${var.vpc_name} public RT A"
    }

}

// Public Route Table A Routes

resource "aws_route" "customer_public_a_default_route" {
    route_table_id = aws_route_table.customer_public_a_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id =  aws_internet_gateway.customer_igw.id
}

// Public Route Table B

resource "aws_route_table" "customer_public_b_rt" {

    vpc_id = aws_vpc.customer_vpc.id   

    tags = {
        Name = "${var.vpc_name} public RT B"
    }

}

// Public Route Table B Routes

resource "aws_route" "customer_public_b_default_route" {
    route_table_id = aws_route_table.customer_public_b_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id =  aws_internet_gateway.customer_igw.id
}

// Public Route Table C

resource "aws_route_table" "customer_public_c_rt" {

    vpc_id = aws_vpc.customer_vpc.id   

    tags = {
        Name = "${var.vpc_name} public RT C"
    }

}

// Public Route Table C Routes

resource "aws_route" "customer_public_c_default_route" {
    route_table_id = aws_route_table.customer_public_c_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id =  aws_internet_gateway.customer_igw.id
}

// Private Route Table A

resource "aws_route_table" "customer_private_a_rt" {

    vpc_id = aws_vpc.customer_vpc.id

        tags = {
        Name = "${var.vpc_name} private RT A"
    }
  
}


resource "aws_route" "customer_private_a_default_route" {
    count = var.require_nat_gateway ? 1 : 0

    route_table_id = aws_route_table.customer_private_a_rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.customer_ngw.*.id[count.index]
}


resource "aws_route_table" "customer_private_b_rt" {

    vpc_id = aws_vpc.customer_vpc.id
 
        tags = {
        Name = "${var.vpc_name} private RT B"
    }
  
}

resource "aws_route" "customer_private_b_default_route" {
    count = var.require_nat_gateway ? 1 : 0

    route_table_id = aws_route_table.customer_private_b_rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.customer_ngw.*.id[count.index]
}

resource "aws_route_table" "customer_private_c_rt" {

    vpc_id = aws_vpc.customer_vpc.id
 
        tags = {
        Name = "${var.vpc_name} private RT C"
    }
  
}

resource "aws_route" "customer_private_c_default_route" {
    count = var.require_nat_gateway ? 1 : 0

    route_table_id = aws_route_table.customer_private_c_rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.customer_ngw.*.id[count.index]
}



resource "aws_route_table_association" "customer_public_a_rt_assoc" {

    route_table_id = aws_route_table.customer_public_a_rt.id
    subnet_id = aws_subnet.publica.id

}

resource "aws_route_table_association" "customer_public_b_rt_assoc" {

    route_table_id = aws_route_table.customer_public_b_rt.id
    subnet_id = aws_subnet.publicb.id

}

resource "aws_route_table_association" "customer_public_c_rt_assoc" {

    route_table_id = aws_route_table.customer_public_c_rt.id
    subnet_id = aws_subnet.publicc.id

}

resource "aws_route_table_association" "customer_private_a_rt_assoc" {

    route_table_id = aws_route_table.customer_private_a_rt.id
    subnet_id = aws_subnet.privatea.id

}

resource "aws_route_table_association" "customer_private_b_rt_assoc" {

    route_table_id = aws_route_table.customer_private_b_rt.id
    subnet_id = aws_subnet.privateb.id

}

resource "aws_route_table_association" "customer_private_c_rt_assoc" {

    route_table_id = aws_route_table.customer_private_c_rt.id
    subnet_id = aws_subnet.privatec.id

}