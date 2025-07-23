variable "name" {
    type = string
    description = "name of cluster"
    default = "tasky-cluster-tf"
}

variable "region" {
    type = string
    description = "aws region"
    default = "us-west-2"
}

variable "vpc_cidr" {
    type = string
    description = "aws vpc cidr"
    default = "10.123.0.0/16"
}

variable "azs" {
    type = list(string)
    description = "availability zones"
    default = ["us-west-2a", "us-west-2b"]
}

variable "public_subnets" {
    type = list(string)
    description = "public subnets"
    default = ["10.123.1.0/24", "10.123.2.0/24"]
}

variable "private_subnets" {
    type = list(string)
    description = "private subnets"
    default = ["10.123.3.0/24", "10.123.4.0/24"]
}

variable "intra_subnets" {
    type = list(string)
    description = "intra subnets"
    default = ["10.123.5.0/24", "10.123.6.0/24"]
}
