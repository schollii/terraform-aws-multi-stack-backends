output "manager_stack_id" {
  value = local.manager_stack_id
}

output "dyndb_backend_locks_table" {
  description = "Table that stores all the terraform tfstate backend locks for stacks managed by this module (including itself!)"
  value = {
    name = aws_dynamodb_table.backend_locks.name
    arn  = aws_dynamodb_table.backend_locks.arn
  }
}

output "tfstate_backends_bucket" {
  value = {
    name          = aws_s3_bucket.tfstate_backends.id
    region        = aws_s3_bucket.tfstate_backends.region
    sse_kms_alias = aws_kms_alias.tfstate_backends.name
  }
}

output "replica_bucket" {
  value = {
    name          = aws_s3_bucket.replica.id
    region        = aws_s3_bucket.replica.region
    sse_kms_alias = aws_kms_alias.replica.name
  }
}

output "access_control_iam_policies_for_tfstates" {
  description = "Policies available to control access to any tfstate (in s3) managed by this manager"
  value = {
    common     = aws_iam_policy.multi_stack_backends_common.name
    manager    = one(aws_iam_policy.multi_stack_backends_manager[*].name)
    sub_stacks = [for p in aws_iam_policy.multi_stack_backends_module : p.name]
  }
}
