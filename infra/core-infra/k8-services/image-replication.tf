locals {
  replicate_to_west = var.aws_region == "us-east-1"
  image_destinations = concat(
    var.replicate_images_to,
    local.replicate_to_west ? [{
      bucket     = aws_s3_bucket.images_dr[0].arn
      account_id = data.aws_caller_identity.current.account_id
    }] : []
  )
}

resource "aws_s3_bucket" "images_dr" {
  count    = local.replicate_to_west ? 1 : 0
  provider = aws.west
  bucket   = "${var.environment}-${var.project_name}-images-${data.aws_caller_identity.current.account_id}-usw1"
}

resource "aws_s3_bucket_versioning" "images_dr" {
  count    = local.replicate_to_west ? 1 : 0
  provider = aws.west
  bucket   = aws_s3_bucket.images_dr[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "images_dr" {
  count    = local.replicate_to_west ? 1 : 0
  provider = aws.west
  bucket   = aws_s3_bucket.images_dr[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "images_dr" {
  count                   = local.replicate_to_west ? 1 : 0
  provider                = aws.west
  bucket                  = aws_s3_bucket.images_dr[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "images_dr" {
  count    = local.replicate_to_west ? 1 : 0
  provider = aws.west
  bucket   = aws_s3_bucket.images_dr[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.images_dr[0].arn, "${aws_s3_bucket.images_dr[0].arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid       = "AllowReplication"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.image_replication[0].arn }
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner",
        ]
        Resource = "${aws_s3_bucket.images_dr[0].arn}/*"
      }
    ]
  })
}

resource "aws_iam_role" "image_replication" {
  count = length(local.image_destinations) > 0 ? 1 : 0

  name = "${var.environment}-${var.project_name}-image-replication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "image_replication" {
  count = length(local.image_destinations) > 0 ? 1 : 0

  name = "replicate-images"
  role = aws_iam_role.image_replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
        ]
        Resource = aws_s3_bucket.images.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
        ]
        Resource = "${aws_s3_bucket.images.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner",
        ]
        Resource = [for destination in local.image_destinations : "${destination.bucket}/*"]
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "images" {
  count = length(local.image_destinations) > 0 ? 1 : 0

  bucket = aws_s3_bucket.images.id
  role   = aws_iam_role.image_replication[0].arn

  depends_on = [aws_s3_bucket_versioning.images, aws_s3_bucket_versioning.images_dr]

  dynamic "rule" {
    for_each = { for idx, destination in local.image_destinations : idx => destination }

    content {
      id       = "images-${rule.key}"
      status   = "Enabled"
      priority = tonumber(rule.key)

      filter {}

      delete_marker_replication {
        status = "Enabled"
      }

      destination {
        bucket        = rule.value.bucket
        account       = rule.value.account_id
        storage_class = "STANDARD"
      }
    }
  }
}
