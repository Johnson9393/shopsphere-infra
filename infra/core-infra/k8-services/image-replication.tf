resource "aws_iam_role" "image_replication" {
  count = length(var.replicate_images_to) > 0 ? 1 : 0

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
  count = length(var.replicate_images_to) > 0 ? 1 : 0

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
        Resource = [for destination in var.replicate_images_to : "${destination.bucket}/*"]
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "images" {
  count = length(var.replicate_images_to) > 0 ? 1 : 0

  bucket = aws_s3_bucket.images.id
  role   = aws_iam_role.image_replication[0].arn

  depends_on = [aws_s3_bucket_versioning.images]

  dynamic "rule" {
    for_each = { for idx, destination in var.replicate_images_to : idx => destination }

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
