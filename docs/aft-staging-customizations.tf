# AFT Staging Account Customizations
# These customizations are specific to staging environment accounts

# Staging-specific IAM Roles
resource "aws_iam_role" "staging_developer_role" {
  name = "StagingDeveloperRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:root"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "staging-developer-access"
          }
        }
      }
    ]
  })

  tags = {
    Environment = "staging"
    Purpose     = "developer-access"
  }
}

resource "aws_iam_role_policy_attachment" "staging_developer_policy" {
  role       = aws_iam_role.staging_developer_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Staging Environment Tags
resource "aws_resourcegroupstaggingapi_resources" "staging_tags" {
  resource_type_filters = ["AWS::AllSupported"]
  
  tag_filter {
    key    = "Environment"
    values = ["staging"]
  }
}

# Staging-specific Budget (Lower limits)
resource "aws_budgets_budget" "staging_budget" {
  name         = "staging-monthly-budget"
  budget_type  = "COST"
  limit_amount = "50"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filters = {
    LinkedAccount = [data.aws_caller_identity.current.account_id]
    Tag = {
      Environment = ["staging"]
    }
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.billing_alert_email]
  }
}

# Staging Auto-Shutdown for Cost Optimization
resource "aws_lambda_function" "staging_auto_shutdown" {
  filename         = "staging_auto_shutdown.zip"
  function_name    = "staging-auto-shutdown"
  role            = aws_iam_role.lambda_auto_shutdown_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      ENVIRONMENT = "staging"
    }
  }

  tags = {
    Environment = "staging"
    Purpose     = "cost-optimization"
  }
}

# EventBridge Rule for Auto-Shutdown (6 PM UTC weekdays)
resource "aws_cloudwatch_event_rule" "staging_shutdown_schedule" {
  name                = "staging-shutdown-schedule"
  description         = "Trigger auto-shutdown for staging resources"
  schedule_expression = "cron(0 18 ? * MON-FRI *)"

  tags = {
    Environment = "staging"
    Purpose     = "cost-optimization"
  }
}

resource "aws_cloudwatch_event_target" "staging_shutdown_target" {
  rule      = aws_cloudwatch_event_rule.staging_shutdown_schedule.name
  target_id = "StagingShutdownTarget"
  arn       = aws_lambda_function.staging_auto_shutdown.arn
}

# Lambda IAM Role for Auto-Shutdown
resource "aws_iam_role" "lambda_auto_shutdown_role" {
  name = "staging-lambda-auto-shutdown-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_auto_shutdown_policy" {
  name = "staging-lambda-auto-shutdown-policy"
  role = aws_iam_role.lambda_auto_shutdown_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "rds:DescribeDBInstances",
          "rds:StopDBInstance",
          "eks:DescribeClusters",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      }
    ]
  })
}

# Required Variables
variable "management_account_id" {
  description = "Management account ID"
  type        = string
}

variable "billing_alert_email" {
  description = "Email for billing alerts"
  type        = string
}

# Data Sources
data "aws_caller_identity" "current" {}