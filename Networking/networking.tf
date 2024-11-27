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