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
    route_table_id = aws_route_table.customer_public_b_rt.id
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

/*
resource "aws_route" "customer_private_a_default_route" {
    route_table_id = aws_route_table.customer_private_a_rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id =  aws_nat_gateway.customer_ngw.id
}
*/

resource "aws_route_table" "customer_private_b_rt" {

    vpc_id = aws_vpc.customer_vpc.id
    # route {

    #     cidr_block = "0.0.0.0/0"
    #     instance_id = aws_instance.NATA.id
    # }

        tags = {
        Name = "${var.vpc_name} private RT B"
    }
  
}



resource "aws_route_table_association" "customer_public_a_rt_assoc" {

    route_table_id = aws_route_table.customer_public_a_rt.id
    subnet_id = aws_subnet.publica.id

}

resource "aws_route_table_association" "customer_public_b_rt_assoc" {

    route_table_id = aws_route_table.customer_public_b_rt.id
    subnet_id = aws_subnet.publicb.id

}

resource "aws_route_table_association" "customer_private_art_assoc" {

    route_table_id = aws_route_table.customer_private_a_rt.id
    subnet_id = aws_subnet.privatea.id

}

resource "aws_route_table_association" "customer_private_brt_assoc" {

    route_table_id = aws_route_table.customer_private_b_rt.id
    subnet_id = aws_subnet.privateb.id

}


# resource "aws_instance" "NATA" {
    
    
#     ami = "ami-0236d0cbbbe64730c"
#     instance_type = "t2.micro"
#     subnet_id = aws_subnet.publica.id
#     associate_public_ip_address = true
#     vpc_security_group_ids = [aws_security_group.NATA_SG.id]
#     source_dest_check = false
#     key_name = "dev03_key"

#     tags = {

#         Name = "NAT Instance A"
#     }


# }

resource "aws_security_group" "NATA_SG" {

    name = "NATA_SG"
    description = "SG For NATA instance"
    vpc_id = aws_vpc.customer_vpc.id

    ingress {

        protocol = "-1"
        from_port = 0
        to_port = 0
        cidr_blocks = [aws_vpc.customer_vpc.cidr_block]

    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }


}