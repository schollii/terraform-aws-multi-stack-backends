#!/usr/bin/env bash

set +eu
usage() {
  echo
  echo "ERROR: missing command line arguments"
  echo
  echo "Usage: $(basename $0) NEW_BUCKET_NAME BACKENDS_MODULE_PATH [CURRENT_BUCKET]"
  echo
  echo "- BACKENDS_MODULE_PATH: can be determined by looking at the terraform state list"
  echo "- CURRENT_BUCKET: only needed if there is no backend.tf (eg it has already been deleted)"
  echo
  echo "Example:"
  echo
  echo "  $(basename $0) new_bucket module.tfstate_manager"
  echo
  echo "which assumes you have a 'module \"tfstate_manager\"' block in your"
  echo "root module, with its 'source' pointing to schollii/multi-stack-backends/aws"
  echo "(or its equivalent github URL)"
  echo
}

new_bucket_name=$1
if [[ -z $new_bucket_name ]]; then
  usage
  exit 1
fi
manager_state_prefix=$2 # ex: "module.tfstate_backends.module.multi_stack_backends"
if [[ -z $manager_state_prefix ]]; then
  usage
  exit 2
fi

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

echo
echo "Moving manager tfstate to local host, without confirmation from user"
rm -f backend.tf
terraform init -migrate-state -force-copy

echo
echo "Making terraform forget about the 2 current buckets:"
terraform state rm $manager_state_prefix.aws_s3_bucket.tfstate_backends
terraform state rm $manager_state_prefix.aws_s3_bucket.replica

echo
echo "Running terraform apply"
echo "which will create the new buckets, replace the lock table for new name,"
echo "create a new `backend.tf` for manager, overwrite the `backend.tf` of all sub-stacks"
echo "in `var.stacks_map`, etc"
echo
terraform apply

# copy tfstates to the new bucket just created, except the old manager state:
echo "Copying the stacks tfstates"
aws s3 cp "s3://$current_bucket" "s3://$new_bucket_name" --recursive
aws s3 rm "s3://$new_bucket_name/_manager_" --recursive

# move the manager's tfstate back into s3
terraform init -migrate-state -force-copy
