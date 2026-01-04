############################
# AWS ORGANIZATIONS FOUNDATION
############################

# AWS Organizations Module
module "aws_organizations" {
  source = "../modules/aws-organizations"

  # Organizational Units
  organizational_units = {
    security = {
      name = "Security"
      tags = {
        Purpose = "security-accounts"
      }
    }
    staging = {
      name = "Staging"
      tags = {
        Purpose = "staging-accounts"
      }
    }
    production = {
      name = "Production"
      tags = {
        Purpose = "production-accounts"
      }
    }
  }

  # Initial AWS Accounts
  accounts = {
    security = {
      name          = "Security Account"
      email         = "security@${local.customer_workload_name}"
      parent_ou_key = "security"
      tags = {
        Purpose = "security-tooling"
      }
    }
    log_archive = {
      name          = "Log Archive Account"
      email         = "log-archive@${local.customer_workload_name}"
      parent_ou_key = "security"
      tags = {
        Purpose = "log-storage"
      }
    }
    audit = {
      name          = "Audit Account"
      email         = "audit@${local.customer_workload_name}"
      parent_ou_key = "security"
      tags = {
        Purpose = "compliance-auditing"
      }
    }
  }

  # Service Control Policies
  service_control_policies = {
    baseline_security = {
      name        = "BaselineSecurityPolicy"
      description = "Baseline security controls for all accounts"
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
            Sid      = "DenyRootUserActions"
            Effect   = "Deny"
            Action   = "*"
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
        Purpose = "baseline-security"
      }
    }
  }

  # Policy Attachments
  policy_attachments = {
    baseline_to_root = {
      policy_key  = "baseline_security"
      target_type = "root"
    }
  }

  # CloudTrail Configuration
  enable_cloudtrail         = true
  cloudtrail_name           = "${local.customer_workload_name}-organization-trail"
  cloudtrail_s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.bucket
  cloudtrail_event_selectors = [
    {
      data_resources = [
        {
          type   = "AWS::S3::Object"
          values = ["arn:aws:s3:::*/*"]
        }
      ]
    }
  ]

  # Default Tags
  default_tags = {
    Environment = var.customer_workload_environment
    Owner       = var.customer_workload_owner
    Project     = "aws-landing-zone"
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
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "AWS:SourceArn" = "arn:aws:cloudtrail:${local.aws_region}:${local.aws_account_id}:trail/${local.customer_workload_name}-organization-trail"
          }
        }
      }
    ]
  })
}