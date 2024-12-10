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

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.Collabo-Repo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Collabo-NAT.id
  }

  tags = {
    Name = "nat rt"
  }
}

resource "aws_route_table_association" "Pub-rt" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.Pub-rt.id
}

resource "aws_route_table_association" "Private-rt" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-rt.id
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

# Configure public Network ACLs to allow inbound HTTP and HTTPS traffic and deny all other traffic

resource "aws_network_acl" "public-acl" {
  vpc_id     = aws_vpc.Collabo-Repo-vpc.id
  subnet_ids = [aws_subnet.public-subnet.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "-1"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0  
    to_port    = 0
  }
}

#Configure private Network ACLs to deny all inbound and outbound traffic

resource "aws_network_acl" "priv-acl" {
  vpc_id     = aws_vpc.Collabo-Repo-vpc.id
  subnet_ids = [aws_subnet.private-subnet.id]

  ingress {
    protocol   = "-1"
    rule_no    = 100  
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"  
    from_port  = 0
    to_port    = 0
  }
}

#Security group for web tier

resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "Allow HTTPS, SSH, HTTP inbound traffic"
  vpc_id      = aws_vpc.Collabo-Repo-vpc.id


  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]      
    }
 
 ingress  {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]      
    }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

#Security group for app tier

resource "aws_security_group" "app-sg" {
  name        = "app-sg"
  description = "Allow HTTPS and HTTP inbound traffic"
  vpc_id      = aws_vpc.Collabo-Repo-vpc.id

ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]      
    }
 
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application-sg"
  }
}

#Security group for database tier 

resource "aws_security_group" "db-sg" {
  name        = "db-sg"
  description = "Allow inbound traffic on port 3306"
  vpc_id      = aws_vpc.Collabo-Repo-vpc.id

ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["172.20.0.0/20"]
  }     

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }   

    tags = {
    Name = "database-sg"
    } 
}
