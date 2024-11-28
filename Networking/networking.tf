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
resource "aws_subnet" "pub-subnet" {
  vpc_id     = aws_vpc.Collabo-Repo-vpc.id
  cidr_block = "172.20.1.0/24"

  tags = {
    Name = "Main-public-subnet"
  }
}

#2 Create private Subnet
resource "aws_subnet" "pub-subnet" {
  vpc_id     = aws_vpc.Collabo-Repo-vpc.id
  cidr_block = "172.20.2.0/24"

  tags = {
    Name = "Main-private-subnet"
  }
}