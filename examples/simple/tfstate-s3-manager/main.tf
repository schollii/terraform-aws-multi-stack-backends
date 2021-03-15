module "tfstate_manager" {
  source = "../../.."

  stacks_map = {
    "../stack-network" = {
      stack_id = "stack-1"
      module_id = "network"
    }
    "../stack-cluster" = {
      stack_id = "stack-1"
      module_id = "cluster"
    }
  }

}