resource "aws_dynamodb_table" "stack_tfstate_backends_lock" {
  for_each = local.stacks_info

  name         = "${each.key}-lock-stack-tfstate-s3-backends"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.tags, {
    StackID = each.key
  })
}

