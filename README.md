This terraform module facilitates the management of terraform state remote 
backends: 

- One bucket for any number of terraform state.
- Support for the notion of "stack", consisting of multiple building blocks
  in the form of terraform root modules. Eg a terraform state for a root 
  module focussed on a stack's network resources, another state for a root
  module focussed on a stack's databases, another for a stack's EKS cluster,
  etc; 
- Automatic generation of the `backend.tf` of each root module of each 
  stack, thus eliminating the chicken-and-egg dance that is otherwise 
  required to provision a new stack
- Support for storing this module's state in s3 in same bucket (via 
  `this_tfstate_in_s3` variable). 
  
The list of stacks to manage is a tree: 

stack ID -> module ID -> information about the stack (currently just 
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
