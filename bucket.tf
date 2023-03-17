resource "aws_kms_key" "tfstate_backends" {
  description             = "Encryption of s3 bucket ${var.backends_bucket_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_alias" "tfstate_backends" {
  target_key_id = aws_kms_key.tfstate_backends.id
  name          = "alias/${var.backends_bucket_name}-bucket"
}

resource "aws_s3_bucket" "tfstate_backends" {
  bucket        = var.backends_bucket_name
  force_destroy = var.buckets_force_destroy

  tags = local.tags
}

resource "aws_s3_bucket_acl" "tfstate_backends" {
  bucket = aws_s3_bucket.tfstate_backends.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "tfstate_backends" {
  bucket = aws_s3_bucket.tfstate_backends.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_backends" {
  bucket = aws_s3_bucket.tfstate_backends.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tfstate_backends.arn
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "tfstate_backends" {
  bucket     = aws_s3_bucket.tfstate_backends.id
  role       = aws_iam_role.replication.arn
  depends_on = [aws_s3_bucket_versioning.tfstate_backends]

  rule {
    id = "replica_configuration"
    filter { prefix = "" }
    status = "Enabled"

    delete_marker_replication {
      status = "Disabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket = aws_s3_bucket.replica.arn
      encryption_configuration {
        replica_kms_key_id = aws_kms_key.replica.arn
      }
      storage_class = "STANDARD"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_bucket" {
  bucket = aws_s3_bucket.tfstate_backends.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "state_force_ssl" {
  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.tfstate_backends.arn,
      "${aws_s3_bucket.tfstate_backends.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "state_force_ssl" {
  bucket = aws_s3_bucket.tfstate_backends.id
  policy = data.aws_iam_policy_document.state_force_ssl.json
}

resource "aws_iam_policy" "multi_stack_backends_common" {
  name = "multi-stack-backends.${local.manager_stack_id}.common"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "${aws_s3_bucket.tfstate_backends.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "${aws_dynamodb_table.backend_locks.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:ListKeys"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey"
      ],
      "Resource": "${aws_kms_key.tfstate_backends.arn}"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "multi_stack_backends_manager" {
  count = var.create_tfstate_access_policy_for_manager ? 1 : 0
  name  = "multi-stack-backends.${local.manager_stack_id}.manager"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "${aws_s3_bucket.tfstate_backends.arn}/${var.manager_s3_key_prefix}/*"
    }
  ]
}
POLICY
}

locals {
  iam_stacks_map = var.create_tfstate_access_policies_for_stacks ? merge([
    for stack_id, modules in var.stacks_map : {
      for module_id, info in modules : "${stack_id}.${module_id}" => {
        stack_id   = stack_id
        key_prefix = "${stack_id}/${module_id}"
      }
  }]...) : {}
}

resource "aws_iam_policy" "multi_stack_backends_module" {
  for_each = local.iam_stacks_map

  name = "multi-stack-backends.${local.manager_stack_id}.${each.key}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "${aws_s3_bucket.tfstate_backends.arn}/${each.value.key_prefix}/*"
    }
  ]
}
POLICY
}
