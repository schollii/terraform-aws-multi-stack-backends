resource "aws_dynamodb_table" "backend_locks" {
  name         = var.backend_locks_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.tags, {
    StackID = local.manager_stack_id
  })
}
