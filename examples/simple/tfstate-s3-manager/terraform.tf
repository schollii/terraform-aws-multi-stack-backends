provider "aws" {
  alias  = "tfstate_backends"
  region = "us-east-1"
}

provider "aws" {
  alias  = "tfstate_backends_replica"
  region = "us-west-1"
}
