locals {
  tags = var.extra_tags

  // if manager specified, use it, but otherwise, it is the module's name with underscores
  // replaced by dash, except if module source is local then it is just manager
  manager_stack_id = (var.manager_stack_id == null ?
    replace(basename(abspath(path.root)), "_", "-")
    : var.manager_stack_id
  )

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

resource "local_file" "this_backend" {
  count = var.manager_tfstate_in_s3 ? 1 : 0

  filename        = "${path.root}/backend.tf"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/manager_backend.tf.tmpl", {
    tfstate_lock_dyndb_table_id = aws_dynamodb_table.backend_locks.id
    tfstate_backends_bucket_id  = aws_s3_bucket.tfstate_backends.id
    tfstate_backends_s3_obj_key = "${var.manager_s3_key_prefix}/terraform.tfstate"
    tfstate_main_region         = data.aws_region.tfstate_backends.name
  })
}

resource "local_file" "stack_backend" {
  for_each        = local.stack_paths_map
  filename        = "${each.value.path}/backend.tf"
  file_permission = "0644"

  content = templatefile("${path.module}/templates/manager_backend.tf.tmpl", {
    tfstate_lock_dyndb_table_id = aws_dynamodb_table.backend_locks.id
    tfstate_backends_bucket_id  = aws_s3_bucket.tfstate_backends.id
    tfstate_backends_s3_obj_key = "${each.value.stack_id}/${each.value.module_id}/terraform.tfstate"
    tfstate_main_region         = data.aws_region.tfstate_backends.name
  })
}
