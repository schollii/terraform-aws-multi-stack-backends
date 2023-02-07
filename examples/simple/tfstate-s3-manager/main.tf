variable "stacks_map" {
  default = {
    stack-1 = {
      network = {
        path = "../stack1-network"
      }
      cluster = {
        path = "../stack1-cluster"
      }
    },
    stack-2 = {
      network = {
        path = "../stack2-network"
      }
      cluster = {
        path = "../stack2-cluster"
      }
    },
  }

}

module "tfstate_manager" {
  //  source  = "schollii/multi-stack-backends/aws"
  source = "../../.."

  providers = {
    aws         = aws.tfstate_backends
    aws.replica = aws.tfstate_backends_replica
  }

  stacks_map           = var.stacks_map
  backends_bucket_name = "schollii-tf-aws-multi-stack-backends-test"
}

output "tfstate_backends_manager" {
  value = module.tfstate_manager
}
