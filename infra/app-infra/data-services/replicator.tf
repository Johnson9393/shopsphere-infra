data "terraform_remote_state" "primary_data" {
  count   = var.primary_state_key == "" ? 0 : 1
  backend = "s3"

  config = {
    bucket = var.primary_state_bucket
    key    = var.primary_state_key
    region = var.state_region
  }
}

data "aws_iam_policy_document" "replicator_assume" {
  count = var.primary_state_key == "" ? 0 : 1

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["kafka.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replicator" {
  count              = var.primary_state_key == "" ? 0 : 1
  name               = "${var.environment}-${var.project_name}-msk-replicator"
  assume_role_policy = data.aws_iam_policy_document.replicator_assume[0].json
}

resource "aws_iam_role_policy" "replicator" {
  count = var.primary_state_key == "" ? 0 : 1
  name  = "replicate"
  role  = aws_iam_role.replicator[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:CreateTopic",
          "kafka-cluster:AlterTopic",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:AlterGroup",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_msk_replicator" "west" {
  count                      = var.primary_state_key == "" ? 0 : 1
  replicator_name            = "${var.environment}-${var.project_name}"
  description                = "Copies Avro events from the primary region while it is healthy"
  service_execution_role_arn = aws_iam_role.replicator[0].arn

  kafka_cluster {
    amazon_msk_cluster {
      msk_cluster_arn = data.terraform_remote_state.primary_data[0].outputs.msk_cluster_arn
    }

    vpc_config {
      subnet_ids          = data.terraform_remote_state.primary_data[0].outputs.private_subnet_ids
      security_groups_ids = [data.terraform_remote_state.primary_data[0].outputs.msk_security_group_id]
    }
  }

  kafka_cluster {
    amazon_msk_cluster {
      msk_cluster_arn = aws_msk_cluster.this.arn
    }

    vpc_config {
      subnet_ids          = local.private_subnet_ids
      security_groups_ids = [aws_security_group.msk.id]
    }
  }

  replication_info_list {
    source_kafka_cluster_arn = data.terraform_remote_state.primary_data[0].outputs.msk_cluster_arn
    target_kafka_cluster_arn = aws_msk_cluster.this.arn
    target_compression_type  = "NONE"

    topic_replication {
      topics_to_replicate = ["shopsphere.*"]
    }

    consumer_group_replication {
      consumer_groups_to_replicate = ["shopsphere.*"]
    }
  }
}
