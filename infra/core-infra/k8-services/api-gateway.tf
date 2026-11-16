locals {
  api_routes = {
    products-read-root = { route_key = "GET /api/products", path = "/api/v1/products", auth = false }
    products-read      = { route_key = "GET /api/products/{proxy+}", path = "/api/v1/products/$request.path.proxy", auth = false }
    products-post      = { route_key = "POST /api/products", path = "/api/v1/products", auth = true }
    products-put       = { route_key = "PUT /api/products/{proxy+}", path = "/api/v1/products/$request.path.proxy", auth = true }
    products-patch     = { route_key = "PATCH /api/products/{proxy+}", path = "/api/v1/products/$request.path.proxy", auth = true }
    products-delete    = { route_key = "DELETE /api/products/{proxy+}", path = "/api/v1/products/$request.path.proxy", auth = true }

    users-register = { route_key = "POST /api/users/register", path = "/api/v1/users/register", auth = false }
    users-login    = { route_key = "POST /api/users/login", path = "/api/v1/users/login", auth = false }
    users-any      = { route_key = "ANY /api/users/{proxy+}", path = "/api/v1/users/$request.path.proxy", auth = true }

    cart-root = { route_key = "ANY /api/cart", path = "/api/v1/cart", auth = true }
    cart-any  = { route_key = "ANY /api/cart/{proxy+}", path = "/api/v1/cart/$request.path.proxy", auth = true }

    orders-root = { route_key = "ANY /api/orders", path = "/api/v1/orders", auth = true }
    orders-any  = { route_key = "ANY /api/orders/{proxy+}", path = "/api/v1/orders/$request.path.proxy", auth = true }

    payments-any = { route_key = "ANY /api/payments/{proxy+}", path = "/api/v1/payments/$request.path.proxy", auth = true }

    notifications-root = { route_key = "ANY /api/notifications", path = "/api/v1/notifications", auth = true }
    notifications-any  = { route_key = "ANY /api/notifications/{proxy+}", path = "/api/v1/notifications/$request.path.proxy", auth = true }
  }
}

data "aws_cognito_user_pools" "shop" {
  name = "${var.environment}-${var.project_name}"
}

data "aws_cognito_user_pool_clients" "shop" {
  user_pool_id = tolist(data.aws_cognito_user_pools.shop.ids)[0]
}

data "aws_lb" "origin" {
  name = "${var.environment}-${var.project_name}"

  depends_on = [kubernetes_ingress_v1.shop]
}

data "aws_lb_listener" "https" {
  load_balancer_arn = data.aws_lb.origin.arn
  port              = 443
}

resource "aws_security_group" "vpc_link" {
  name        = "${var.environment}-${var.project_name}-vpc-link"
  description = "Amazon API Gateway VPC link to the shop load balancer"
  vpc_id      = data.aws_eks_cluster.this.vpc_config[0].vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.cluster.cidr_block]
  }
}

data "aws_vpc" "cluster" {
  id = data.aws_eks_cluster.this.vpc_config[0].vpc_id
}

resource "aws_security_group_rule" "alb_from_api" {
  type                     = "ingress"
  description              = "Amazon API Gateway VPC link"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = tolist(data.aws_lb.origin.security_groups)[0]
  source_security_group_id = aws_security_group.vpc_link.id
}

resource "aws_apigatewayv2_vpc_link" "shop" {
  name               = "${var.environment}-${var.project_name}"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids         = data.aws_eks_cluster.this.vpc_config[0].subnet_ids
}

resource "aws_apigatewayv2_api" "shop" {
  name          = "${var.environment}-${var.project_name}"
  protocol_type = "HTTP"
  description   = "Public API edge for ${var.environment}. Routes are forwarded to the service load balancer."

  cors_configuration {
    allow_origins  = ["https://shop.${var.environment}.${var.domain_name}"]
    allow_methods  = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_headers  = ["authorization", "content-type", "traceparent", "x-trace-id"]
    expose_headers = ["x-trace-id", "traceparent"]
    max_age        = 3600
  }
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.shop.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito"

  jwt_configuration {
    audience = data.aws_cognito_user_pool_clients.shop.client_ids
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${tolist(data.aws_cognito_user_pools.shop.ids)[0]}"
  }
}

resource "aws_apigatewayv2_integration" "service" {
  for_each = local.api_routes

  api_id             = aws_apigatewayv2_api.shop.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.shop.id
  integration_uri    = data.aws_lb_listener.https.arn

  request_parameters = {
    "overwrite:path"        = each.value.path
    "overwrite:header.host" = "origin.${var.environment}.${var.domain_name}"
  }
}

resource "aws_apigatewayv2_route" "service" {
  for_each = local.api_routes

  api_id             = aws_apigatewayv2_api.shop.id
  route_key          = each.value.route_key
  target             = "integrations/${aws_apigatewayv2_integration.service[each.key].id}"
  authorization_type = each.value.auth ? "JWT" : "NONE"
  authorizer_id      = each.value.auth ? aws_apigatewayv2_authorizer.cognito.id : null
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/shopsphere/${var.environment}/api-gateway"
  retention_in_days = 30
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.shop.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId   = "$context.requestId"
      routeKey    = "$context.routeKey"
      status      = "$context.status"
      error       = "$context.error.message"
      integration = "$context.integration.error"
      ip          = "$context.identity.sourceIp"
    })
  }

  default_route_settings {
    throttling_burst_limit   = 200
    throttling_rate_limit    = 100
    detailed_metrics_enabled = true
  }

  depends_on = [aws_apigatewayv2_route.service]
}
