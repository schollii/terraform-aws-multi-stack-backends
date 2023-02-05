terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "replica"
  region = "us-west-1"
}