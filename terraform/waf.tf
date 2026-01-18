# AWS WAF v2 - Centralized Web Application Firewall
# Provides protection for both CloudFront distributions and API Gateway endpoints

############################
# SHARED WAF RESOURCES
############################

# IP set for trusted IPs (shared across all services)
resource "aws_wafv2_ip_set" "trusted_ips_cloudfront" {
  count = var.create_cloudfront_distributions ? 1 : 0

  name  = "${replace(local.customer_workload_name, ".", "-")}-trusted-ips-cloudfront"
  scope = "CLOUDFRONT"

  ip_address_version = "IPV4"

  # Add your trusted IP addresses here
  addresses = [
    # Example: "203.0.113.0/24",
    # Add your office/home IP addresses
  ]

  tags = merge(local.common_tags, {
    Name    = "${local.customer_workload_name}-trusted-ips-cloudfront"
    Purpose = "waf-trusted-ip-allowlist-cloudfront"
  })
}

# IP set for trusted IPs (regional scope for API Gateway)
resource "aws_wafv2_ip_set" "trusted_ips_regional" {
  name  = "${replace(local.customer_workload_name, ".", "-")}-trusted-ips-regional"
  scope = "REGIONAL"

  ip_address_version = "IPV4"

  # Add your trusted IP addresses here (same as CloudFront)
  addresses = [
    # Example: "203.0.113.0/24",
    # Add your office/home IP addresses
  ]

  tags = merge(local.common_tags, {
    Name    = "${local.customer_workload_name}-trusted-ips-regional"
    Purpose = "waf-trusted-ip-allowlist-regional"
  })
}

############################
# WAF WEB ACL FOR CLOUDFRONT
############################

# WAF Web ACL for CloudFront distributions
resource "aws_wafv2_web_acl" "cloudfront" {
  count = var.create_cloudfront_distributions ? 1 : 0

  name  = "${replace(local.customer_workload_name, ".", "-")}-cloudfront-waf"
  scope = "CLOUDFRONT"

  description = "WAF Web ACL for CloudFront distributions"

  default_action {
    allow {}
  }

  # Allow health checks and monitoring
  rule {
    name     = "AllowHealthChecks"
    priority = 0

    action {
      allow {}
    }

    statement {
      or_statement {
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

        statement {
          byte_match_statement {
            search_string = "/metrics"
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
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowHealthChecksMetric"
      sampled_requests_enabled   = true
    }
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

  # Rate limiting rule for CloudFront
  rule {
    name     = "CloudFrontRateLimitRule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000 # Higher limit for frontend traffic
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CloudFrontRateLimitRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  # Geo blocking rule
  rule {
    name     = "GeoBlockRule"
    priority = 4

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = var.waf_blocked_countries
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoBlockRuleMetric"
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
# WAF WEB ACL FOR API GATEWAY
############################

# WAF Web ACL per environment for API Gateway protection
resource "aws_wafv2_web_acl" "api_gateway" {
  for_each = toset(var.workload_environments)

  name  = "${replace(local.customer_workload_name, ".", "-")}-${each.value}-api-waf"
  scope = "REGIONAL"

  description = "WAF Web ACL for API Gateway ${each.value} environment"

  default_action {
    allow {}
  }

  # Allow health checks and monitoring
  rule {
    name     = "AllowHealthChecks"
    priority = 0

    action {
      allow {}
    }

    statement {
      or_statement {
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

        statement {
          byte_match_statement {
            search_string = "/metrics"
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
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowHealthChecksMetric-${each.value}"
      sampled_requests_enabled   = true
    }
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

        # Exclude rules that might block legitimate API traffic
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
      metric_name                = "AWSManagedRulesCommonRuleSetMetric-${each.value}"
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
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric-${each.value}"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting rule for API protection
  rule {
    name     = "APIRateLimitRule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit # Lower limit for APIs
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "APIRateLimitRuleMetric-${each.value}"
      sampled_requests_enabled   = true
    }
  }

  # Geo blocking rule
  rule {
    name     = "GeoBlockRule"
    priority = 4

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = var.waf_blocked_countries
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoBlockRuleMetric-${each.value}"
      sampled_requests_enabled   = true
    }
  }

  # SQL injection protection
  rule {
    name     = "SQLInjectionRule"
    priority = 5

    action {
      block {}
    }

    statement {
      sqli_match_statement {
        field_to_match {
          all_query_arguments {}
        }
        text_transformation {
          priority = 1
          type     = "URL_DECODE"
        }
        text_transformation {
          priority = 2
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionRuleMetric-${each.value}"
      sampled_requests_enabled   = true
    }
  }

  # XSS protection
  rule {
    name     = "XSSRule"
    priority = 6

    action {
      block {}
    }

    statement {
      xss_match_statement {
        field_to_match {
          all_query_arguments {}
        }
        text_transformation {
          priority = 1
          type     = "URL_DECODE"
        }
        text_transformation {
          priority = 2
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "XSSRuleMetric-${each.value}"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.common_tags, {
    Name        = "${local.customer_workload_name}-${each.value}-api-waf"
    Environment = each.value
    Purpose     = "api-gateway-web-application-firewall"
  })

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${replace(local.customer_workload_name, ".", "-")}-${each.value}-APIGatewayWAF"
    sampled_requests_enabled   = true
  }
}

############################
# WAF ASSOCIATIONS
############################

# Associate WAF Web ACL with API Gateway stages
resource "aws_wafv2_web_acl_association" "api_gateway" {
  for_each = toset(var.workload_environments)

  resource_arn = aws_api_gateway_stage.main[each.value].arn
  web_acl_arn  = aws_wafv2_web_acl.api_gateway[each.value].arn

  depends_on = [
    aws_api_gateway_stage.main,
    aws_wafv2_web_acl.api_gateway
  ]
}

############################
# WAF LOGGING CONFIGURATION
############################

# CloudWatch log group for CloudFront WAF logs
resource "aws_cloudwatch_log_group" "waf_cloudfront" {
  count = var.create_cloudfront_distributions ? 1 : 0

  name              = "aws-waf-logs-cloudfront-${replace(local.customer_workload_name, ".", "-")}"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name    = "${replace(local.customer_workload_name, ".", "-")}-waf-cloudfront-logs"
    Purpose = "waf-cloudfront-logging"
  })
}

# CloudWatch log group for API Gateway WAF logs
resource "aws_cloudwatch_log_group" "waf_api_gateway" {
  for_each = toset(var.workload_environments)

  name              = "aws-waf-logs-api-gateway-${replace(local.customer_workload_name, ".", "-")}-${each.value}"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name        = "${replace(local.customer_workload_name, ".", "-")}-${each.value}-waf-api-logs"
    Environment = each.value
    Purpose     = "waf-api-gateway-logging"
  })
}

# WAF logging configuration for CloudFront
resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  count = var.create_cloudfront_distributions ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.cloudfront[0].arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_cloudfront[0].arn]

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

  depends_on = [aws_wafv2_web_acl.cloudfront]
}

# WAF logging configuration for API Gateway
resource "aws_wafv2_web_acl_logging_configuration" "api_gateway" {
  for_each = toset(var.workload_environments)

  resource_arn            = aws_wafv2_web_acl.api_gateway[each.value].arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_api_gateway[each.value].arn]

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

  redacted_fields {
    single_header {
      name = "x-api-key"
    }
  }

  depends_on = [aws_wafv2_web_acl.api_gateway]
}

############################
# CLOUDWATCH ALARMS
############################

# CloudWatch alarm for CloudFront high request rate
resource "aws_cloudwatch_metric_alarm" "cloudfront_high_request_rate" {
  count = var.create_cloudfront_distributions ? 1 : 0

  alarm_name          = "${local.customer_workload_name}-cloudfront-high-request-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "AllowedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "2000"
  alarm_description   = "This metric monitors CloudFront request rate"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    WebACL = aws_wafv2_web_acl.cloudfront[0].name
    Region = "CloudFront"
  }

  tags = merge(local.common_tags, {
    Name    = "${local.customer_workload_name}-cloudfront-high-request-rate"
    Purpose = "waf-monitoring-alarm"
  })
}

# CloudWatch alarm for API Gateway high request rate
resource "aws_cloudwatch_metric_alarm" "api_high_request_rate" {
  for_each = toset(var.workload_environments)

  alarm_name          = "${local.customer_workload_name}-${each.value}-api-high-request-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "AllowedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "This metric monitors API Gateway request rate"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    WebACL = aws_wafv2_web_acl.api_gateway[each.value].name
    Region = local.aws_region
  }

  tags = merge(local.common_tags, {
    Name        = "${local.customer_workload_name}-${each.value}-api-high-request-rate"
    Environment = each.value
    Purpose     = "waf-monitoring-alarm"
  })
}

# CloudWatch alarm for blocked requests
resource "aws_cloudwatch_metric_alarm" "api_blocked_requests" {
  for_each = toset(var.workload_environments)

  alarm_name          = "${local.customer_workload_name}-${each.value}-api-blocked-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors blocked requests to API Gateway"
  alarm_actions       = [] # Add SNS topic ARN for notifications

  dimensions = {
    WebACL = aws_wafv2_web_acl.api_gateway[each.value].name
    Region = local.aws_region
  }

  tags = merge(local.common_tags, {
    Name        = "${local.customer_workload_name}-${each.value}-api-blocked-requests"
    Environment = each.value
    Purpose     = "waf-security-alarm"
  })
}