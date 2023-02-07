#!/usr/bin/env bash

set +eou

tf_resources=$(terraform plan -no-color | grep "will be created" | grep aws_s3_bucket_ | cut -f 4 -d " " | sort)
BACKENDS_BUCKET_NAME=$(sed -En 's/ *bucket *= *"([a-z0-9][a-z0-9.-]+[a-z0-9])"/\1/p' backend.tf)

echo "Importing bucket properties"
for resource in $tf_resources; do
  bucket_name=$BACKENDS_BUCKET_NAME
  if [[ $resource =~ replica$ ]]; then
    bucket_name=${BACKENDS_BUCKET_NAME}-replica
  fi
  echo "Importing $resource for bucket $bucket_name"

  terraform import "$resource" "$bucket_name"
  echo -e "Done importing\n"
done
