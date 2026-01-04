# AFT Global Customizations
# These customizations are applied to ALL accounts created through AFT
# This ensures consistent baseline security and compliance across all accounts

# Baseline Security Configuration
resource "aws_config_configuration_recorder" "baseline" {
  name     = "baseline-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "baseline" {
  name           = "baseline-config-delivery-channel"
  s3_bucket_name = var.config_bucket_name
}

# CloudTrail for Account-Level Logging
resource "aws_cloudtrail" "account_trail" {
  name                          = "account-cloudtrail"
  s3_bucket_name               = var.cloudtrail_bucket_name
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/*"]
    }
  }

  tags = {
    Environment = var.environment
    Purpose     = "account-audit-logging"
  }
}

# Baseline IAM Password Policy
resource "aws_iam_account_password_policy" "baseline" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers               = true
  require_uppercase_characters   = true
  require_symbols               = true
  allow_users_to_change_password = true
  max_password_age              = 90
  password_reuse_prevention     = 12
}

# Default VPC Removal (Security Best Practice)
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC - To Be Removed"
  }
}

# GuardDuty Enablement
resource "aws_guardduty_detector" "baseline" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Environment = var.environment
    Purpose     = "threat-detection"
  }
}

# Security Hub Enablement
resource "aws_securityhub_account" "baseline" {
  enable_default_standards = true
}

# Cost and Billing Alerts
resource "aws_budgets_budget" "account_budget" {
  name         = "account-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filters = {
    LinkedAccount = [data.aws_caller_identity.current.account_id]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.billing_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.billing_alert_email]
  }
}

# Required Data Sources
data "aws_caller_identity" "current" {}

# Required Variables
variable "config_bucket_name" {
  description = "S3 bucket for AWS Config"
  type        = string
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket for CloudTrail logs"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "100"
}

variable "billing_alert_email" {
  description = "Email for billing alerts"
  type        = string
}