#Provider
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.77.0"
    }
  }
}
#1 Create VPC
resource "aws_vpc" "Collabo-Repo-vpc" {
  cidr_block       = "172.20.0.0/20"
  instance_tenancy = "default"

  tags = {
    Name = "Collabo-Repo-vpc"
  }
}

resource "aws_internet_gateway" "Collabo-igw" {
  vpc_id = aws_vpc.Collabo-Repo-vpc.id

  tags = {
    Name = "Collabo-igw"
  }
}

resource "aws_internet_gateway_attachment" "Collabo-att" {
  internet_gateway_id = aws_internet_gateway.Collabo-igw.id
  vpc_id              = aws_vpc.Collabo-Repo-vpc.id
}

#2 Create public Subnet
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.Collabo-Repo-vpc.id
  cidr_block = "172.20.1.0/24"

  tags = {
    Name = "Main-public-subnet"
  }
}

#2 Create private Subnet
resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.Collabo-Repo-vpc.id
  cidr_block = "172.20.2.0/24"

  tags = {
    Name = "Main-privatesubnet"
  }
}

resource "aws_route_table" "Pub-rt" {
  vpc_id = aws_vpc.Collabo-Repo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Collabo-igw.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "Pub-rt" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.Pub-rt.id
}

resource "aws_eip" "Collabo-NAT" {
  vpc = true
}

resource "aws_nat_gateway" "Collabo-NAT" {
allocation_id = aws_eip.Collabo-NAT.id
subnet_id     = aws_subnet.public-subnet.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.Collabo-igw]
}