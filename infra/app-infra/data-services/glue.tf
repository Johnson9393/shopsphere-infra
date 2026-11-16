resource "aws_glue_registry" "domain" {
  registry_name = "${var.environment}-${var.project_name}"
  description   = "Avro contracts for ${var.environment} ShopSphere events"
}

resource "aws_glue_schema" "order_event" {
  schema_name       = "OrderEvent"
  registry_arn      = aws_glue_registry.domain.arn
  data_format       = "AVRO"
  compatibility     = "BACKWARD"
  schema_definition = file("${path.module}/schemas/order_event.avsc")
}

resource "aws_glue_schema" "payment_event" {
  schema_name       = "PaymentEvent"
  registry_arn      = aws_glue_registry.domain.arn
  data_format       = "AVRO"
  compatibility     = "BACKWARD"
  schema_definition = file("${path.module}/schemas/payment_event.avsc")
}
