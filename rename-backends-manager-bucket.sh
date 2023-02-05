#!/usr/bin/env bash

set +eou

new_bucket_name=$1
manager_state_prefix=$2 # ex: "module.tfstate_backends.module.multi_stack_backends"

current_bucket=$3
if [[ -z $current_bucket ]]; then
  current_bucket=$(sed -En 's/ *bucket *= *"([a-z0-9][a-z0-9.-]+[a-z0-9])"/\1/p' backend.tf)
  echo "Current bucket is: $current_bucket"
  read -p "Is this correct (y/n)? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^(y|Y)$ ]]; then
    exit 0
  fi
fi

# move manager tfstate to local host, without confirmation from user
rm backend.tf
terraform init -migrate-state -force-copy

# make terraform forget about the 2 current buckets:
terraform state rm $manager_state_prefix.aws_s3_bucket.tfstate_backends
terraform state rm $manager_state_prefix.aws_s3_bucket.replica

# run `terraform apply` which will create the new buckets, replace the lock table for new name,
#   create a new `backend.tf` for manager, overwrite the `backend.tf` of all sub-stacks
#   in `var.stacks_map`, etc
terraform apply

# copy tfstates to the new bucket just created, except the old manager state:
aws s3 cp "s3://$current_bucket" "s3://$new_bucket_name"
aws s3 rm "s3://$new_bucket_name/_manager_" --recursive

# move the manager's tfstate back into s3
terraform init -migrate-state -force-copy
