resource "aws_wafv2_web_acl" "edge" {
  name  = "${var.environment}-${var.project_name}-edge"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "rate-limit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "common"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-common"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "bad-inputs"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "sqli"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-sqli"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-edge"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl" "alb" {
  name  = "${var.environment}-${var.project_name}-alb"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "common"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.environment}-alb-common"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-alb"
    sampled_requests_enabled   = true
  }
}
