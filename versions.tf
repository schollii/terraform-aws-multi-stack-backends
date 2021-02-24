terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 0.14"
}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias = "replica"
  region = "us-west-1"
}