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
  name          = "alias/${var.backends_bucket_name}-bucket-replica"
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

  policy = templatefile("${path.module}/replica_policy.json.tmpl", {
    tfstate_backends_region      = data.aws_region.tfstate_backends.name
    tfstate_backends_bucket_arn  = aws_s3_bucket.tfstate_backends.arn
    tfstate_backends_kms_key_arn = aws_kms_key.tfstate_backends.arn

    replica_region      = data.aws_region.replica.name
    replica_bucket_arn  = aws_s3_bucket.replica.arn
    replica_kms_key_arn = aws_kms_key.replica.arn
  })
}

resource "aws_iam_policy_attachment" "replication" {
  name       = "${var.backends_bucket_name}-bucket-replication"
  roles      = [aws_iam_role.replication.name]
  policy_arn = aws_iam_policy.replication.arn
}

#---------------------------------------------------------------------------------------------------
# Bucket Policies
#---------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "replica_force_ssl" {
  statement {
    sid       = "AllowSSLRequestsOnly"
    actions   = ["s3:*"]
    effect    = "Deny"
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
  force_destroy = var.buckets_force_destroy

  tags = local.tags
}

resource "aws_s3_bucket_acl" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id
  acl      = "private"
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
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
