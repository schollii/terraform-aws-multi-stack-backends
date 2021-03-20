resource "aws_dynamodb_table" "this_backend_lock" {
  name         = "${local.this_stack_id}-lock-tfstate-in-s3"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.tags, {
    StackID = local.this_stack_id
  })
}

resource "aws_dynamodb_table" "stack_tfstate_backend_lock" {
  for_each = local.stacks_map

  name         = "${each.key}-stack-lock-tfstate-in-s3"
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

