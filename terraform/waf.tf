# AWS WAF v2 for CloudFront protection
# Provides web application firewall protection for frontend distributions

############################
# WAF WEB ACL FOR CLOUDFRONT
############################

# WAF Web ACL for CloudFront distributions
resource "aws_wafv2_web_acl" "cloudfront" {
  name  = "${replace(local.customer_workload_name, ".", "-")}-cloudfront-waf"
  scope = "CLOUDFRONT"

  description = "WAF Web ACL for CloudFront distributions"

  default_action {
    allow {}
  }

  # AWS Managed Rule - Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        # Exclude rules that might block legitimate traffic
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "SizeRestrictions_BODY"
        }

        rule_action_override {
          action_to_use {
            count {}
          }
          name = "GenericRFI_BODY"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

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
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 3

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
      metric_name                = "RateLimitRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  # Geo blocking rule (optional - can be customized)
  rule {
    name     = "GeoBlockRule"
    priority = 4

    action {
      block {}
    }

    statement {
      geo_match_statement {
        # Block traffic from high-risk countries
        country_codes = ["CN", "RU", "KP", "IR"]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoBlockRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  # Custom rule to allow health checks
  rule {
    name     = "AllowHealthChecks"
    priority = 0

    action {
      allow {}
    }

    statement {
      byte_match_statement {
        search_string = "/health"
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
        positional_constraint = "STARTS_WITH"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowHealthChecksMetric"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.common_tags, {
    Name    = "${local.customer_workload_name}-cloudfront-waf"
    Purpose = "cloudfront-web-application-firewall"
  })

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${replace(local.customer_workload_name, ".", "-")}-CloudFrontWAF"
    sampled_requests_enabled   = true
  }
}

############################
# WAF LOGGING CONFIGURATION
############################

# CloudWatch log group for WAF logs
resource "aws_cloudwatch_log_group" "waf_cloudfront" {
  name              = "/aws/wafv2/cloudfront/${local.customer_workload_name}"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name    = "${local.customer_workload_name}-waf-cloudfront-logs"
    Purpose = "waf-cloudfront-logging"
  })
}

# WAF logging configuration
resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  resource_arn            = aws_wafv2_web_acl.cloudfront.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_cloudfront.arn]

  # Redact sensitive fields from logs
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}

############################
# WAF IP SET FOR ALLOWLIST
############################

# IP set for trusted IPs (can be used for admin access)
resource "aws_wafv2_ip_set" "trusted_ips" {
  name  = "${replace(local.customer_workload_name, ".", "-")}-trusted-ips"
  scope = "CLOUDFRONT"

  ip_address_version = "IPV4"

  # Add your trusted IP addresses here
  addresses = [
    # Example: "203.0.113.0/24",
    # Add your office/home IP addresses
  ]

  tags = merge(local.common_tags, {
    Name    = "${local.customer_workload_name}-trusted-ips"
    Purpose = "waf-trusted-ip-allowlist"
  })
}

# Rule to allow trusted IPs (commented out by default)
# Uncomment and add to the web ACL rules if needed
/*
resource "aws_wafv2_rule" "allow_trusted_ips" {
  name     = "AllowTrustedIPs"
  priority = 0

  action {
    allow {}
  }

  statement {
    ip_set_reference_statement {
      arn = aws_wafv2_ip_set.trusted_ips.arn
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                 = "AllowTrustedIPsMetric"
    sampled_requests_enabled    = true
  }
}
*/