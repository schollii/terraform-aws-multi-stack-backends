This terraform module facilitates the management of tfstate backends: 

- a bucket dedicated to storing the tfstate of multiple stacks
- each stack can consist of multiple root modules (eg a root module for
  network, another for databases, another for EKS cluster, etc) each 
  having their own tfstate
- the `backend.tf` of each root module of each stack is 
  managed automatically generated
- modifying one root module of a stack locks the whole stack, thereby
  preventing the modification of another root module of the stack which
  might depend on the first module. 
- This module's state can also be stored in s3 via `this_tfstate_in_s3`
  variable. 
  
The list of stacks to manage is a map of stack id to a map of module ID
to an object that contains information about the stack (currently just 
the path). 

Example: 
```hcl
# your main.tf for the tfstate manager
module "tfstate_manager" {
  source  = "schollii/multi-stack-backends/aws"

  stacks_map = {
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
```

See the [examples/simple/README.md](examples/simple/README.md) for details
including diagrams that illustrate the different pieces managed by this 
module. 

### Acknowledgements

My code used some of https://github.com/nozaq/terraform-aws-remote-state-s3-backend as starting point. 
