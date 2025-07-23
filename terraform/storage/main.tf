terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "db-backup-bucket" {
  bucket = "billy-tasky-db-backup-bucket-tf"
  tags = {
    automation        = "terraform"
  }
}
