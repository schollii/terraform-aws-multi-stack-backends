terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.replica]
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  alias = "replica"
}