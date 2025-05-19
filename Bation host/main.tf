terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.region
}

data "aws_availability_zones" "available" {}
# Create VPC

resource "aws_vpc" "bastion_vpc" {
  cidr_block = var.vpc_cid
  tags = {
    Name = "bastion-vpc"
  }
}

# Create public subnet

resource "aws_subnet" "bastion_public_subnet" {
  vpc_id            = aws_vpc.bastion_vpc.id
  cidr_block        = var.public_subnet_cid
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "bastion-public-subnet"
  }
}

# Create private subnet

resource "aws_subnet" "bastion_private_subnet" {
  vpc_id            = aws_vpc.bastion_vpc.id
  cidr_block        = var.private_subnet_cid
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "bastion-private-subnet"
  }
}

# create internet gateway

resource "aws_internet_gateway" "bastion_igw" {
  vpc_id = aws_vpc.bastion_vpc.id

  tags = {
    Name = "bastion-igw"
  }
}

# creatre nat gateway

resource "aws_nat_gateway" "bastion_nat_gw" {
  allocation_id = aws_eip.bastion_nat_eip.id
  subnet_id     = aws_subnet.bastion_public_subnet.id

  tags = {
    Name = "bastion-nat-gw"
  }
}

# create elastic ip for nat gateway

resource "aws_eip" "bastion_nat_eip" {
  vpc = true

  tags = {
    Name = "bastion-nat-eip"
  }
}

# create route table for public subnet

resource "aws_route_table" "bastion_public_route_table" {
  vpc_id = aws_vpc.bastion_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bastion_igw.id
  }
  tags = {
    Name = "bastion-public-route-table"
  }
}

# associate public route table with public subnet

resource "aws_route_table_association" "bastion_public_subnet_association" {
    subnet_id      = aws_subnet.bastion_public_subnet.id
    route_table_id = aws_route_table.bastion_public_route_table.id
  }


# create route table for private subnet 

resource "aws_route_table" "bastion_private_route_table" {
  vpc_id = aws_vpc.bastion_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.bastion_nat_gw.id
  }
  tags = {
    Name = "bastion-private-route-table"
  }
}

# associate private route table with private subnet

resource "aws_route_table_association" "bastion_private_subnet_association" {
    subnet_id      = aws_subnet.bastion_private_subnet.id
    route_table_id = aws_route_table.bastion_private_route_table.id
  }

# create security group for public subnet

resource "aws_security_group" "bastion_public_sg" {
  vpc_id = aws_vpc.bastion_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "bastion-public-sg"
  }   
}

# create security group for private subnet

resource "aws_security_group" "bastion_private_sg" {
  vpc_id = aws_vpc.bastion_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }   
  tags = {
    Name = "bastion-private-sg"
  }
}

# create bastion host
resource "aws_instance" "bastion_host" {
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  subnet_id     = aws_subnet.bastion_public_subnet.id
  key_name      = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.bastion_public_sg.id]

  tags = {
    Name = "bastion-host"
  }
}

# create private instance
resource "aws_instance" "private_instance" {
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  subnet_id     = aws_subnet.bastion_private_subnet.id
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.bastion_private_sg.id]

  tags = {
    Name = "private-instance"
  }
}

