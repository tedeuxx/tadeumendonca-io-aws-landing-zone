############################
# AWS ORGANIZATIONS FOUNDATION
############################

# AWS Organizations
resource "aws_organizations_organization" "main" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "account.amazonaws.com"
  ]

  feature_set = "ALL"

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]
}

# Organizational Units
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.main.roots[0].id

  tags = {
    Name        = "Security-OU"
    Environment = var.customer_workload_environment
    Purpose     = "security-accounts"
  }
}

resource "aws_organizations_organizational_unit" "development" {
  name      = "Development"
  parent_id = aws_organizations_organization.main.roots[0].id

  tags = {
    Name        = "Development-OU"
    Environment = var.customer_workload_environment
    Purpose     = "development-accounts"
  }
}

resource "aws_organizations_organizational_unit" "staging" {
  name      = "Staging"
  parent_id = aws_organizations_organization.main.roots[0].id

  tags = {
    Name        = "Staging-OU"
    Environment = var.customer_workload_environment
    Purpose     = "staging-accounts"
  }
}

resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = aws_organizations_organization.main.roots[0].id

  tags = {
    Name        = "Production-OU"
    Environment = var.customer_workload_environment
    Purpose     = "production-accounts"
  }
}

# Initial AWS Accounts
resource "aws_organizations_account" "security" {
  name      = "Security Account"
  email     = "security@${local.customer_workload_name}"
  parent_id = aws_organizations_organizational_unit.security.id

  tags = {
    Name        = "Security-Account"
    Environment = var.customer_workload_environment
    Purpose     = "security-tooling"
  }

  lifecycle {
    ignore_changes = [role_name]
  }
}

resource "aws_organizations_account" "log_archive" {
  name      = "Log Archive Account"
  email     = "log-archive@${local.customer_workload_name}"
  parent_id = aws_organizations_organizational_unit.security.id

  tags = {
    Name        = "LogArchive-Account"
    Environment = var.customer_workload_environment
    Purpose     = "log-storage"
  }

  lifecycle {
    ignore_changes = [role_name]
  }
}

resource "aws_organizations_account" "audit" {
  name      = "Audit Account"
  email     = "audit@${local.customer_workload_name}"
  parent_id = aws_organizations_organizational_unit.security.id

  tags = {
    Name        = "Audit-Account"
    Environment = var.customer_workload_environment
    Purpose     = "compliance-auditing"
  }

  lifecycle {
    ignore_changes = [role_name]
  }
}

# Service Control Policies
resource "aws_organizations_policy" "baseline_scp" {
  name        = "BaselineSecurityPolicy"
  description = "Baseline security controls for all accounts"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyLeavingOrganization"
        Effect = "Deny"
        Action = [
          "organizations:LeaveOrganization",
          "account:CloseAccount"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyRootUserActions"
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalType" = "Root"
          }
        }
        Principal = "*"
      },
      {
        Sid    = "RequireMFAForHighRiskActions"
        Effect = "Deny"
        Action = [
          "iam:DeleteRole",
          "iam:DeleteUser",
          "iam:DeleteAccessKey",
          "iam:CreateUser",
          "iam:CreateRole"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "Baseline-SCP"
    Environment = var.customer_workload_environment
    Purpose     = "baseline-security"
  }
}

# Attach SCP to Root
resource "aws_organizations_policy_attachment" "baseline_scp_root" {
  policy_id = aws_organizations_policy.baseline_scp.id
  target_id = aws_organizations_organization.main.roots[0].id
}

# Organization-wide CloudTrail
resource "aws_cloudtrail" "organization_trail" {
  name                          = "${local.customer_workload_name}-organization-trail"
  s3_bucket_name               = aws_s3_bucket.cloudtrail_bucket.bucket
  include_global_service_events = true
  is_multi_region_trail        = true
  is_organization_trail        = true
  enable_logging               = true

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/*"]
    }
  }

  tags = {
    Name        = "${local.customer_workload_name}-organization-trail"
    Environment = var.customer_workload_environment
    Purpose     = "organization-audit-logging"
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}

# S3 Bucket for CloudTrail
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "${local.customer_workload_name}-organization-cloudtrail-${random_id.bucket_suffix.hex}"
  force_destroy = false

  tags = {
    Name        = "${local.customer_workload_name}-organization-cloudtrail"
    Environment = var.customer_workload_environment
    Purpose     = "cloudtrail-logs"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket_versioning" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_bucket_encryption" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket_pab" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail S3 Bucket Policy
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:${local.aws_region}:${local.aws_account_id}:trail/${local.customer_workload_name}-organization-trail"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
            "AWS:SourceArn" = "arn:aws:cloudtrail:${local.aws_region}:${local.aws_account_id}:trail/${local.customer_workload_name}-organization-trail"
          }
        }
      }
    ]
  })
}