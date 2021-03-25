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
  source = "../../.."

  stacks_map = var.stacks_map
}