resource "local_file" "this_backend" {
  filename        = "${path.root}/backend.tf"
  file_permission = "0644"

  content = <<EOF
terraform {
  backend "s3" {
    bucket = "${aws_s3_bucket.tfstate_backends.id}"
    region = "us-east-1"
    encrypt = true

    dynamodb_table = "${aws_dynamodb_table.backend_locks.id}"
    key = "${var.manager_s3_key_prefix}/terraform.tfstate"
  }
}
EOF
}

locals {
  // convert the stacks map to a map of paths to stack and module ID
  stack_paths_map = merge([
    for stack_id, modules in var.stacks_map : {
      for module_id, info in modules : "${stack_id}/${module_id}" => {
        stack_id  = stack_id
        module_id = module_id
        path      = info.path
      }
    }
  ]...)
}

resource "local_file" "stack_backend" {
  for_each        = local.stack_paths_map
  filename        = "${each.value.path}/backend.tf"
  file_permission = "0644"

  content = <<EOF
terraform {
  backend "s3" {
    bucket = "${aws_s3_bucket.tfstate_backends.id}"
    region = "us-east-1"
    encrypt = true

    dynamodb_table = "${aws_dynamodb_table.backend_locks.id}"
    key = "${each.value.stack_id}/${each.value.module_id}/terraform.tfstate"
  }
}
EOF
}