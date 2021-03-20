resource "local_file" "this_backend" {
  filename = "${path.root}/backend.tf"
  file_permission = "0644"

  content = <<EOF
terraform {
  backend "s3" {
    bucket = "${aws_s3_bucket.tfstate_backends.id}"
    region = "us-east-1"
    encrypt = true

    dynamodb_table = "${aws_dynamodb_table.this_backend_lock.id}"
    key = "${local.this_stack_id}/terraform.tfstate"
  }
}
EOF
}

resource "local_file" "stack_backend" {
  for_each = local.stacks_map
  filename = "${each.value.path}/backend.tf"
  file_permission = "0644"

  content = <<EOF
terraform {
  backend "s3" {
    bucket = "${aws_s3_bucket.tfstate_backends.id}"
    region = "us-east-1"
    encrypt = true

    dynamodb_table = "${aws_dynamodb_table.stack_tfstate_backend_lock[each.key].id}"
    key = "${each.key}/${each.value.module_id}/terraform.tfstate"
  }
}
EOF
}