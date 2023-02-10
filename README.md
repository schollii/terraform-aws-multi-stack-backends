This terraform module makes it easy to boostrap the storage of terraform state remote backends
in AWS S3. It is basically an alternative to using Terraform Cloud, insofar as tfstate storage goes.

I created this module because I got tired of having to do a song and dance every time I was standing
up a new stack: create terraform code in a separate folder from the stack code to create several AWS
resources specific to the stack (namely its own bucket for storing its tfstate, its own lock table
etc), run `terraform init` and  `apply`, then create a `backend.tf` file for that folder and
run `terraform init -migrate-state`, THEN create a `backends.tf` file in the stack's folder with the
right values based on the tfstate folder. That got tiring really quickly, and I didn't want to have
to store tfstate in Terraform Cloud mostly because I didn't like the idea of depending on a third
party (relative to AWS) to host the all-important tfstate which contains sensitive information.

And then when your stacks get large enough, you'll want to subdivide them into smaller "substacks",
eg one for the VPC/networking, one for some servers, one for databases, etc.

So this module automates much of this toil. In its simplest form, you use this module inside a "
tfstate backends manager" root module that you create, you just have to give it a simple mapping
of (arbitrary) stack names to their paths on the filesystem. Then run `terraform apply`, and finally
run `terraform init -migrate-state -force-copy` for each stack and the manager module itself (so
even the manager stores its state in S3!) and you're DONE! You can go about your business of writing
your infra code! AND the bucket storing your tfstates will have auto-replication to a different
region, both buckets will be server-side encrypted and versioned, each stack will have its own lock,
etc.

This "tfstate backends manager" module (maybe that's what I should have called it) supports
more advanced uses as well:

- any stack can have substacks; each will have its own key in the S3 bucket
- you could have multiple "managers" in one AWS account, each can act as the host for a
  separate set of stacks
- the module can generate IAM policies for each stack that limit access to that stacks' tfstate only
  in either read-only mode or read-write; you can then attach those policies to your IAM
  users/roles/groups (you do that part)

The list of stacks to manage is a tree-like map:

stack ID -> sub-stack ID -> information about the stack or sub-stack

Currently the info consists only of the filesystem path, but more info could be added in the future.
When a stack does not have sub-stacks, you define just one sub-stack ID, and give it a name like
"all" or "main".

## Examples

Example:

```hcl
# your main.tf for the tfstate manager
module "tfstate_manager" {
  source = "schollii/multi-stack-backends/aws"

  stacks_map = {
    stack-1 = {
      all = {
        path = "../stack1"
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

The keys like "network" and "cluster" are entirely up to you.
See the [examples/simple/README.md](examples/simple/README.md) for details
including diagrams that illustrate the different pieces managed by this
module.

There isn't much more to using this module than the above and the examples. The remaining
sections provide useful info for various tasks.

## Renaming a tfstates manager bucket

It may happen that the backends manager bucket needs to be renamed. Eg,
following some naming policy changes in your organization. Unfortunately AWS does not make this
easy: buckets cannot be renamed. The following procedure is one that I use so that all AWS
resources get renamed according to the new bucket name:

1. Ensure that no one else will be running terraform apply on either the manager or any of its
   stacks / sub-stacks.
2. Change the value of `backends_bucket_name` used by the backends manager terraform code (this new
   value is
   referred to here as `NEW_BACKENDS_BUCKET_NAME`).
3. Examine `scripts/rename-backends-manager-bucket.sh` to understand what it does. Test it out first
   on your system, eg on the `examples/simple/tfstate-s3-manager` folder.
   (REMINDER: per the license terms described in this git repo, this script is provided as-is
   without any warranty implied - it is your responsibility to ensure that it will not cause loss
   of data!).
4. Run that script `scripts/rename-backends-manager-bucket.sh NEW_BUCKET_NAME`.
5. Any of your `terraform_remote_state` data sources that point to the old bucket name of this
   manager need to be have their bucket argument adjusted.
6. Run `terraform plan` in all of the stacks managed by this backends manager, and confirm that no
   init is needed and no changes are planned.
7. Once you are satisfied that the new setup is working, you can manually delete the 2 old buckets.

That should be it!

## Upgrades

This section documents upgrades necessary between adjacent major releases.

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
   to plan creation of those resources. This is ok, but if you prefer (like me) not to, you can
   import them into the tfstate. I use the bash script `scripts/upgrade-to-1.0.sh`. Again before
   using it, examine it and check that it will work with your version of bash and your setup.
   Testing is easy: add an "echo" in front of the terraform commands.

## Acknowledgements

My code used some of https://github.com/nozaq/terraform-aws-remote-state-s3-backend as a starting
point. 

