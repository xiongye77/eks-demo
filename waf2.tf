provider "aws" {
  alias      = "wafv2_provider"
  region     = "us-east-1"
}

resource "aws_wafv2_web_acl" "my_web_acl" {
  provider  = "aws.wafv2_provider"
  name  = "my-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimit"
    priority = 1

    action {
      block {}
    }

    statement {

      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = 500
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "my-web-acl"
    sampled_requests_enabled   = false
  }
}

