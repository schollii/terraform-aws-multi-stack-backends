This terraform module facilitates the management of infrastructure represented
by multiple terraform states in S3: 

- Creates one bucket to store all tf states you configure it to manage; so you 
  create the bucket and associated replication / IAM once, and never worry about 
  shared tf state again
- Supports the subdivision of a "stack" into multiple terraform root 
  modules. Each stack has its own base key in the bucket managed by 
  multi-stack-backends. Eg a stack consisting of a root module for the VPC + 
  network (subnets etc), another root module for the databases, and another 
  root module for the EKS cluster, would have all 3 associated tf states
  under "s3://multi-tfstate-bucket/your-stack-name".
- One tfvars file shows all stacks managed by a multi-stack-backends 
  instance, and all root-modules in that stack. No more guessing which 
  root modules are interrelated!
- Automatic generation of the `backend.tf` of each root module of each 
  stack mentioned in the tfvars file, thus eliminating the chicken-and-egg 
  dance that is otherwise required to provision each root module for sharing
  in AWS S3.
- Bucket replication and versioning and IAM roles to limit access to individual 
  stack states
  
The list of stacks to manage is represented in a tfvars file: 

stack ID -> module ID -> information about the stack (currently just 
the path). 

Example: 
```hcl
# your main.tf for the tfstate manager
module "tfstate_manager" {
  source  = "schollii/multi-stack-backends/aws"
  version = "0.6.1"

  stacks_map = {
    stack-1 = {
      network = {
        path = "../stack1/network"
      }
      cluster = {
        path = "../stack1/cluster"
      }
    },
    stack-2 = {
      network = {
        path = "../stack2/network"
      }
      fargate = {
        path = "../stack2/fargate"
      }
      databases = {
        path = "../stack2/databases"
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
