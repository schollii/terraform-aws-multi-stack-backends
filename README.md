This terraform module facilitates the management of terraform state remote backends:

- One bucket for any number of terraform tfstates.
- Based on the notion of "stacks", each consisting of multiple building blocks in the form of
  terraform root modules (called sub-stacks). Eg a terraform state for a root module focussed on a
  stack's network resources, another state for a root module focussed on a stack's databases,
  another for a stack's EKS cluster, etc.
- Automatic generation of the `backend.tf` of each sub-stack (ie root module) of each stack, thus
  eliminating the chicken-and-egg dance that is otherwise required to provision a new stack.
- Support for storing this module's state in s3 in same bucket (via `manager_tfstate_in_s3`
  variable).
- Generate policies that can be used to control access to the backends
  manager, and to all sub-stacks of specific stacks.

The list of stacks to manage is a tree:

stack ID -> sub-stack ID -> information about the stack (currently just
the path).

## Examples

Example:

```hcl
# your main.tf for the tfstate manager
module "tfstate_manager" {
  source = "schollii/multi-stack-backends/aws"

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

## Renaming the tfstates bucket

It may happen that the backends bucket (and therefore its replica) need to be renamed, eg following
some naming policy changes in your organization. AWS does not provide a means of doing this
directly. The following procedure is one that I use.

1. WARN your team that no one can use terraform on this terraform module, and ENSURE THAT
   TERRAFORM PLAN SHOWS NO CHANGES NEEDED.
2. change the value of `backends_bucket_name` (this new value is referred to here
   as `NEW_BACKENDS_BUCKET_NAME`).
3. determine the path to the manager module in your tfstate. The easiest is to run `terraform state
   list | grep aws_s3_bucket` look at your code or output of terraform state list).
4. run `script/rename-backends-manager-bucket.sh NEW_BUCKET_NAME MODULE_PATH` (per the license
   terms, this is provided as-is without any warranty - you assume all responsibility!).
5. If you had any `terraform_remote_state` in your sub-stacks, point them to the new bucket name.
6. run `terraform apply` in any of the sub-stacks, this should show no init and no changes needed.
7. manually delete the 2 old buckets when you are satisfied it is safe to do so.

## Upgrades

### 0.6.x to 1.0

1. (Optional) The module no longer assumes that IAM policies for the tfstate access are required.
   These policies are not needed by the module, they are merely a convenience (making it easy for
   you to control access to the tfstates stored in the backend bucket). To generate the policies as
   in 0.6, set one or both `create_tfstate_access_polic*` variables to true, depending on your
   needs.
2. (Optional) The module no longer assumes a default set of tags. Only `var.extra_tags` is used, and
   by default it is empty. The terraform plan will clearly say what the old values were, if you
   need some of them.
3. Rename variable `this_tfstate_in_s3` to `manager_tfstate_in_s3`
4. The module now requires a value for `backends_bucket_name` (it no longer provides a default).
   This won't likely affect you because you almost certainly had to specify a bucket name anyway,
   due
   to [AWS uniqueness constraints on S3 bucket names](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html).
   But if you were able to not specify it (eg if you were the first to use that default bucket name
   in yours AWS partition), you must now add `backends_bucket_name = "tfstate-s3-backends"`.
   However, I highly recommend that you rename your backends bucket to something unique to you or
   your organization / employer. Eg `ORG_NAME-GROUP_NAME-tfstate-backends`. The procedure to do this
   is in a separate section of this readme.
5. The module itself no longer defines providers, as recommended in the terraform documentation.
   Rather, it requires they be passed in to the module. Therefore, before applying,
    - ensure you have these two blocks (as done
      in `examples/simple/tfstate-s3-manager/terraform.tf`):
      ```hcl
      provider "aws" {
        alias  = "tfstate_backends"
        region = "us-east-1"
      }
    
      provider "aws" {
        alias  = "tfstate_backends_replica"
        region = "us-west-1"
      }
      ```
    - add the following to the module block that references this module (as done in
      `examples/simple/tfstate-s3-manager/terraform.tf`):
      ```hcl
      providers = {
        aws = aws.tfstate_backends
        aws.replica = aws.tfstate_backends_replica
      }
      ```
6. (Optional) The module now uses the `aws_s3_bucket_*` resources instead of the inline blocks that
   the AWS provider has deprecated, like acl, server-side encryption, etc. This will cause terraform
   to plan generating those resources, unless you import them into your tfstate. I use the bash
   script `scripts/upgrade-to-1.0.sh`. I recommend testing it first: open the script in an editor
   and add an "echo" in front of the terraform commands to verify that it makes sense, as there are
   too many possibilities to say for sure that the script will work as-is.

## Acknowledgements

My code used some of https://github.com/nozaq/terraform-aws-remote-state-s3-backend as starting
point. 

