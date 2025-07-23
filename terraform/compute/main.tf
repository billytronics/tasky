terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-west-2"
}

resource "aws_instance" "database-server" {
  ami           = "ami-08bfb3ff75119bd97"
  instance_type = "t3a.medium"

  tags = {
    Name = "billy-db-server-tf"
    automation = "terraform"
  }
}

