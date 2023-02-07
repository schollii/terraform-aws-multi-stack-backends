#!/usr/bin/env bash

set +eu

usage() {
  echo
  echo "ERROR: missing command line arguments"
  echo
  echo "Usage: $(basename "$0") NEW_BUCKET_NAME [CURRENT_BUCKET]"
  echo
  echo "- NEW_BUCKET_NAME: name for new backends bucket (must match 'backends_bucket_name'"
  echo "    that you specified in your tf code)"
  echo "- CURRENT_BUCKET: current name of backends bucket (only needed if there is "
  echo "    no backend.tf, eg it has already been deleted)"
  echo
  echo "Example:"
  echo
  echo "  $(basename "$0") new_bucket"
  echo
}

new_bucket_name=$1
if [[ -z $new_bucket_name ]]; then
  usage
  exit 1
fi

current_bucket_name=$2
if [[ -z $current_bucket_name ]]; then
  if [[ ! -f ./backend.tf ]]; then
    echo "ERROR: No ./backend.tf file found. You must specify the bucket name as third arg."
    exit 8
  fi

  current_bucket_name=$(sed -En 's/ *bucket *= *"([a-z0-9][a-z0-9.-]+[a-z0-9])"/\1/p' backend.tf)
  if [[ -z $current_bucket_name ]]; then
    echo "ERROR: Could not determine current bucket from ./backend.tf."
    exit 10
  fi
fi

if [[ $current_bucket_name == "$new_bucket_name" ]]; then
  echo "ERROR: current and new bucket names are the same!!"
  exit 5
fi

manager_state_prefix=$(terraform state list | sed -En 's/(.*)\.aws_s3_bucket\.tfstate_backends/\1/p')
if [[ -z $manager_state_prefix ]]; then
  echo "ERROR: could not determine which tf resource is backends bucket"
  exit 2
fi

# Confirm:
echo "Current bucket: $current_bucket_name"
echo "New bucket:     $new_bucket_name"
echo "Manager tfstate prefix: $manager_state_prefix"
read -p "Is this correct (y/n)? " -n 1 -r
echo
if [[ ! $REPLY =~ ^(y|Y)$ ]]; then
  exit 0
fi

echo
echo "Moving manager tfstate to local host, without confirmation from user"
rm -f backend.tf
terraform init -migrate-state -force-copy

echo
echo "Making terraform forget about the 2 current buckets:"
terraform state rm "$manager_state_prefix.aws_s3_bucket.tfstate_backends"
terraform state rm "$manager_state_prefix.aws_s3_bucket.replica"

echo
echo "Running terraform apply"
echo "which will create the new buckets, replace the lock table for new name,"
echo "create a new 'backend.tf' for manager, overwrite the 'backend.tf' of all sub-stacks"
echo "in 'var.stacks_map', etc"
echo
terraform apply

# copy tfstates to the new bucket just created, except the old manager state:
echo "Copying the stacks tfstates"
aws s3 cp "s3://$current_bucket_name/" "s3://$new_bucket_name/" --recursive
aws s3 rm "s3://$new_bucket_name/_manager_/" --recursive

# move the manager's tfstate back into s3
terraform init -migrate-state -force-copy

echo
echo "DONE!"
echo "NOTE: VERIFY that all tfstates have been properly transfered. Eg, run"
echo "'terraform plan' in all substacks: no changes should be planned."
echo "ONCE YOU ARE SATISFIED, YOU CAN MANUALLY DELETE THE TWO PREVIOUS BUCKETS."
echo "Example: aws s3 rb \"s3://$current_bucket_name\" --force"
echo "Example: aws s3 rb \"s3://${current_bucket_name}-replica\" --force"
