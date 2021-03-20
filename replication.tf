#---------------------------------------------------------------------------------------------------
# KMS Key to Encrypt S3 Bucket
#---------------------------------------------------------------------------------------------------
resource "aws_kms_key" "replica" {
  provider = aws.replica

  description             = "Encryption of s3 bucket ${var.backends_bucket_name} replica"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_alias" "replica" {
  provider = aws.replica

  target_key_id = aws_kms_key.replica.id
  name = "alias/${var.backends_bucket_name}-bucket-replica"
}

#---------------------------------------------------------------------------------------------------
# IAM Role for Replication
# https://docs.aws.amazon.com/AmazonS3/latest/dev/crr-replication-config-for-kms-objects.html
#---------------------------------------------------------------------------------------------------
resource "aws_iam_role" "replication" {
  name = "${var.backends_bucket_name}-bucket-replication"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
POLICY

  tags = local.tags
}

resource "aws_iam_policy" "replication" {
  name = "${var.backends_bucket_name}-bucket-replication"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.tfstate_backends.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.tfstate_backends.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.replica.arn}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "${aws_kms_key.tfstate_backends.arn}",
      "Condition": {
        "StringLike": {
          "kms:ViaService": "s3.${data.aws_region.tfstate_backends.name}.amazonaws.com",
          "kms:EncryptionContext:aws:s3:arn": [
            "${aws_s3_bucket.tfstate_backends.arn}/*"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": "${aws_kms_key.replica.arn}",
      "Condition": {
        "StringLike": {
          "kms:ViaService": "s3.${data.aws_region.replica.name}.amazonaws.com",
          "kms:EncryptionContext:aws:s3:arn": [
            "${aws_s3_bucket.replica.arn}/*"
          ]
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "replication" {
  name = "${var.backends_bucket_name}-bucket-replication"
  roles      = [aws_iam_role.replication.name]
  policy_arn = aws_iam_policy.replication.arn
}

#---------------------------------------------------------------------------------------------------
# Bucket Policies
#---------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "replica_force_ssl" {
  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.replica.arn,
      "${aws_s3_bucket.replica.arn}/*"
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
#---------------------------------------------------------------------------------------------------
# Buckets
#---------------------------------------------------------------------------------------------------
data "aws_region" "tfstate_backends" {
}

data "aws_region" "replica" {
  provider = aws.replica
}

resource "aws_s3_bucket" "replica" {
  provider = aws.replica

  bucket        = "${var.backends_bucket_name}-replica"
  force_destroy = var.s3_bucket_force_destroy
  acl           = "private"

  versioning {
    enabled = true
  }

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "replica_force_ssl" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id
  policy   = data.aws_iam_policy_document.replica_force_ssl.json
}
