resource "aws_kms_key" "tfstate_backends" {
  description             = "Encryption of s3 bucket ${var.backends_bucket_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_alias" "tfstate_backends" {
  target_key_id = aws_kms_key.tfstate_backends.id
  name = "alias/${var.backends_bucket_name}-bucket"
}

resource "aws_s3_bucket" "tfstate_backends" {
  bucket        = var.backends_bucket_name
  force_destroy = var.s3_bucket_force_destroy
  acl           = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.tfstate_backends.arn
      }
    }
  }

  replication_configuration {
    role = aws_iam_role.replication.arn

    rules {
      id     = "replica_configuration"
      prefix = ""
      status = "Enabled"

      source_selection_criteria {
        sse_kms_encrypted_objects {
          enabled = true
        }
      }

      destination {
        bucket             = aws_s3_bucket.replica.arn
        replica_kms_key_id = aws_kms_key.replica.arn
        storage_class      = "STANDARD"
      }
    }
  }

  tags = local.tags
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

resource "aws_s3_bucket_public_access_block" "tfstate_bucket" {
  bucket = aws_s3_bucket.tfstate_backends.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "this_tfstate_backend" {
  name = "${local.manager_stack_id}-backends-manager"

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
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "${aws_s3_bucket.tfstate_backends.arn}/${var.manager_s3_key_prefix}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "${aws_dynamodb_table.this_backend_lock.arn}"
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

resource "aws_iam_policy" "tfstate_stack_backend" {
  for_each = local.stacks_map

  name = "${each.key}-stack-${each.value.module_id}-tfstate-s3-backend"

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
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "${aws_s3_bucket.tfstate_backends.arn}/${each.key}/${each.value.module_id}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "${aws_dynamodb_table.stack_tfstate_backend_lock[each.key].arn}"
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
