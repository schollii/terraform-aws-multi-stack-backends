resource "local_file" "stack_backends" {
  for_each = toset(local.stack_dirs)
  filename = "${each.key}/backend.tf"
  file_permission = "0644"

  content = <<EOF
terraform {
  backend "s3" {
    bucket = "${aws_s3_bucket.tfstate_backends.id}"
    region = "us-east-1"
    encrypt = true

    dynamodb_table = "${aws_dynamodb_table.stack_tfstate_backends_lock[each.key].id}"
    key = "${each.key}/cluster.tfstate"
  }
}
EOF
}