resource "aws_security_group" "msk" {
  name        = "${var.environment}-${var.project_name}-msk"
  description = "MSK IAM clients from this environment private subnets"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description = "Kafka IAM from the environment private subnets"
    from_port   = 9098
    to_port     = 9098
    protocol    = "tcp"
    cidr_blocks = concat(local.private_cidrs, var.extra_client_cidrs)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_msk_configuration" "this" {
  name           = "${var.environment}-${var.project_name}-msk"
  kafka_versions = ["3.6.0"]

  server_properties = <<-PROPS
    auto.create.topics.enable=true
    delete.topic.enable=true
  PROPS
}

resource "aws_msk_cluster" "this" {
  cluster_name           = "${var.environment}-${var.project_name}"
  kafka_version          = "3.6.0"
  number_of_broker_nodes = 2

  broker_node_group_info {
    instance_type   = var.msk_instance_type
    client_subnets  = slice(local.private_subnet_ids, 0, 2)
    security_groups = [aws_security_group.msk.id]

    storage_info {
      ebs_storage_info {
        volume_size = var.msk_volume_size
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.this.arn
    revision = aws_msk_configuration.this.latest_revision
  }

  client_authentication {
    sasl {
      iam = true
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }
}

resource "aws_secretsmanager_secret" "kafka" {
  name        = "${var.project_name}/${var.environment}/kafka"
  description = "MSK bootstrap brokers for ${var.environment}. Clients authenticate with IAM."
  kms_key_id  = aws_kms_key.data.arn
}

resource "aws_secretsmanager_secret_version" "kafka" {
  secret_id = aws_secretsmanager_secret.kafka.id
  secret_string = jsonencode({
    bootstrap_brokers = aws_msk_cluster.this.bootstrap_brokers_sasl_iam
    registry_name     = aws_glue_registry.domain.registry_name
    orders_topic      = "shopsphere.orders"
    payments_topic    = "shopsphere.payments"
  })
}
