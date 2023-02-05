This terraform module facilitates the management of terraform state remote
backends:

- One bucket for any number of terraform state.
- Support for the notion of "stack", consisting of multiple building blocks
  in the form of terraform root modules. Eg a terraform state for a root
  module focussed on a stack's network resources, another state for a root
  module focussed on a stack's databases, another for a stack's EKS cluster,
  etc.
- Automatic generation of the `backend.tf` of each sub-stack (ie root module) of each
  stack, thus eliminating the chicken-and-egg dance that is otherwise
  required to provision a new stack.
- Support for storing this module's state in s3 in same bucket (via
  `this_tfstate_in_s3` variable).
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

It may happen that the backends bucket name needs changing, eg following some naming policy
changes in your organization. AWS does not provide a means of doing this directly. 
Here is the procedure that I use:

1. set `this_tfstate_in_s3` to false and comment out the items in `stacks_map`
2. run `terraform apply` in your root module that calls the `multi_stack_backends` module. This will
   delete all the `backend.tf` files that had been created by this root module.
3. run `terraform init -migrate-state` (optionally with the `-force-copy` arg) to migrate the
   manager's tfstate out of s3
4. run that same command for all the sub-stacks (ie root modules) that you commented out. I use a
   loop
   like `for ss in paths-to-substacks; do echo $ss; cd $ss; terraform init ...; cd - > /dev/null; done`
5. create a local backup of the bucket: `aws s3 cp s3://BACKENDS_BUCKET_NAME . --recursive`
6. now that all tfstates have been copied from the bucket to localhost, and the bucket has been
   backed up just in case, you can change the value of `backends_bucket_name` given to this module
   and run `terraform apply`
7. undo step 1: set `this_tfstate_in_s3` to true
8. undo step 2: uncomment the items from that step
9. undo step 3 by re-running that exact same command `terraform init -migrate-state`
10. undo step 4 by re-running that exact same command for all sub-stacks
11. If you had any `terraform_remote_state`, point them to the new location
12. running `terraform apply` in any of the sub-stacks should show no init and no changes needed

Here is a different procedure that has fewer steps, some are simpler than previous procedure, and
you don't need to delete the original bucket until the very end. It will be especially useful if you
have many sub-stacks. HOWEVER I have not tested yet, so please test it first.

1. change the value of `backends_bucket_name`
2. delete the `backend.tf` of this manager module
3. run `terraform init -migrate-state` to bring the manager's tfstate back to local
4. make terraform forget about the 2 current buckets:
   ```
   terraform state rm module.tfstate_backends.module.multi_stack_backends.aws_s3_bucket.tfstate_backends
   terraform state rm module.tfstate_backends.module.multi_stack_backends.aws_s3_bucket.replica
   ```
5. run `terraform apply` which will create the new buckets, replace the lock table for new name,
   create a new `backend.tf` for manager, overwrite the `backend.tf` of all sub-stacks
   in `var.stacks_map`, etc
6. copy tfstates to the new bucket just created, except the old manager state:
   ```
   aws s3 cp s3://BACKENDS_BUCKET_NAME s3://NEW_BACKENDS_BUCKET_NAME
   aws s3 rm s3://NEW_BACKENDS_BUCKET_NAME/_manager_
   ```
7. run `terraform init -migrate-state` to move the manager's tfstate back into s3
8. If you had any `terraform_remote_state` in your sub-stacks, point them to the new location
9. running `terraform apply` in any of the sub-stacks should show no init and no changes needed
10. manually delete the 2 old buckets

## Upgrades

### 0.6.x to 1.0

- The module no longer assumes that IAM policies for the tfstate access are needed. These policies
  are not needed by the module, they are merely a convenience (making it easy for you to control
  access to the tfstates stored in the backend bucket). To generate the policies as in 0.6, set one
  or both `create_tfstate_access_polic*` variables to true, depending on your needs.
- The module now requires a value for `backends_bucket_name`. This won't likely affect you because
  you almost certainly had to specify a name anyway, due to AWS uniqueness constraints on S3 bucket
  names. But if you somehow got away with not specifying it, you must now
  add `backends_bucket_name = "tfstate-s3-backends"`. However, I highly recommend that you rename
  your backends bucket to something unique to you or your organization / employer.
  Eg `ORG_NAME-GROUP_NAME-tfstate-backends`. The procedure to do this is in a separate section of
  this readme.
- The module now uses the `aws_s3_bucket_*` resources instead of the inline blocks that the AWS
  provider has deprecated, like acl, server-side encryption, etc. This will cause terraform to
  plan generating those resources, unless you import them into your tfstate. To do this, run the
  following import commands in a shell, after setting `BACKENDS_BUCKET_NAME` to the value of
  `backends_bucket_name`:
  ```
  terraform import module.tfstate_backends.module.multi_stack_backends.aws_s3_bucket_acl.replica $BACKENDS_BUCKET_NAME
  terraform import module.tfstate_backends.module.multi_stack_backends.aws_s3_bucket_acl.tfstate_backends $BACKENDS_BUCKET_NAME
  terraform import module.tfstate_backends.module.multi_stack_backends.aws_s3_bucket_replication_configuration.tfstate_backends $BACKENDS_BUCKET_NAME
  terraform import module.tfstate_backends.module.multi_stack_backends.aws_s3_bucket_server_side_encryption_configuration.tfstate_backends $BACKENDS_BUCKET_NAME
  terraform import module.tfstate_backends.module.multi_stack_backends.aws_s3_bucket_versioning.replica $BACKENDS_BUCKET_NAME
  terraform import module.tfstate_backends.module.multi_stack_backends.aws_s3_bucket_versioning.tfstate_backends $BACKENDS_BUCKET_NAME
  ```

## Acknowledgements

My code used some of https://github.com/nozaq/terraform-aws-remote-state-s3-backend as starting
point. 
