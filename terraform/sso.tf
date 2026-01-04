############################
# AWS SSO (IDENTITY CENTER)
############################

# Get the SSO instance (AWS SSO is enabled automatically in organizations)
data "aws_ssoadmin_instances" "main" {}

locals {
  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}

############################
# PERMISSION SETS
############################

# Organization Admin Permission Set
resource "aws_ssoadmin_permission_set" "organization_admin" {
  name             = "OrganizationAdmin"
  description      = "Full administrative access across all accounts in the organization"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H" # 8 hours

  tags = {
    Name        = "OrganizationAdmin"
    Environment = var.customer_workload_environment
    Purpose     = "organization-administration"
  }
}

# Production Admin Permission Set
resource "aws_ssoadmin_permission_set" "production_admin" {
  name             = "ProductionAdmin"
  description      = "Administrative access to production accounts with enhanced security"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H" # 4 hours

  tags = {
    Name        = "ProductionAdmin"
    Environment = var.customer_workload_environment
    Purpose     = "production-administration"
  }
}

# Developer Access Permission Set
resource "aws_ssoadmin_permission_set" "developer_access" {
  name             = "DeveloperAccess"
  description      = "Developer access to staging and development resources"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H" # 8 hours

  tags = {
    Name        = "DeveloperAccess"
    Environment = var.customer_workload_environment
    Purpose     = "development-access"
  }
}

# Read Only Permission Set
resource "aws_ssoadmin_permission_set" "read_only" {
  name             = "ReadOnly"
  description      = "Read-only access across all accounts for auditing and monitoring"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT12H" # 12 hours

  tags = {
    Name        = "ReadOnly"
    Environment = var.customer_workload_environment
    Purpose     = "read-only-access"
  }
}

############################
# MANAGED POLICY ATTACHMENTS
############################

# Organization Admin - Full AWS Access
resource "aws_ssoadmin_managed_policy_attachment" "organization_admin_policy" {
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.organization_admin.arn
}

# Production Admin - Power User Access (no IAM user management)
resource "aws_ssoadmin_managed_policy_attachment" "production_admin_policy" {
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  permission_set_arn = aws_ssoadmin_permission_set.production_admin.arn
}

# Developer Access - Power User Access
resource "aws_ssoadmin_managed_policy_attachment" "developer_access_policy" {
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  permission_set_arn = aws_ssoadmin_permission_set.developer_access.arn
}

# Read Only - Read Only Access
resource "aws_ssoadmin_managed_policy_attachment" "read_only_policy" {
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn
}

############################
# CUSTOM INLINE POLICIES
############################

# Production Admin - Additional IAM permissions for specific tasks
resource "aws_ssoadmin_permission_set_inline_policy" "production_admin_iam" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowIAMRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:UpdateRole",
          "iam:TagRole",
          "iam:UntagRole"
        ]
        Resource = [
          "arn:aws:iam::*:role/eks-*",
          "arn:aws:iam::*:role/lambda-*",
          "arn:aws:iam::*:role/rds-*",
          "arn:aws:iam::*:role/*-service-role"
        ]
      },
      {
        Sid    = "AllowServiceLinkedRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole",
          "iam:DeleteServiceLinkedRole"
        ]
        Resource = "*"
      }
    ]
  })
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.production_admin.arn
}

# Developer Access - Restricted IAM permissions
resource "aws_ssoadmin_permission_set_inline_policy" "developer_access_restrictions" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyProductionResourceModification"
        Effect = "Deny"
        Action = [
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster",
          "s3:DeleteBucket",
          "ec2:TerminateInstances"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
          StringLike = {
            "aws:PrincipalTag/Environment" = "production"
          }
        }
      }
    ]
  })
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_access.arn
}

############################
# ACCOUNT ASSIGNMENTS
############################

# Organization Admin - Management Account Access
resource "aws_ssoadmin_account_assignment" "organization_admin_management" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization_admin.arn

  principal_id   = var.sso_admin_user_id
  principal_type = "USER"

  target_id   = local.aws_account_id
  target_type = "AWS_ACCOUNT"
}

# Production Admin - Production Accounts (when created)
# Note: This will be expanded when production workload accounts are created

# Developer Access - Staging Accounts (when created)
# Note: This will be expanded when staging workload accounts are created

# Read Only - All Accounts
resource "aws_ssoadmin_account_assignment" "read_only_management" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn

  principal_id   = var.sso_readonly_group_id
  principal_type = "GROUP"

  target_id   = local.aws_account_id
  target_type = "AWS_ACCOUNT"
}

############################
# SSO CONFIGURATION
############################

# Application Assignment Configuration (for future SAML apps)
# This can be extended to integrate with external identity providers

# Audit Logging Configuration
resource "aws_cloudtrail" "sso_audit_trail" {
  name                          = "${local.customer_workload_name}-sso-audit-trail"
  s3_bucket_name                = aws_s3_bucket.sso_audit_bucket.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
    exclude_management_event_sources = []
  }

  tags = {
    Name        = "${local.customer_workload_name}-sso-audit-trail"
    Environment = var.customer_workload_environment
    Purpose     = "sso-audit-logging"
  }
}

# S3 Bucket for SSO Audit Logs
resource "aws_s3_bucket" "sso_audit_bucket" {
  bucket        = "${local.customer_workload_name}-sso-audit-${random_id.bucket_suffix.hex}"
  force_destroy = false

  tags = {
    Name        = "${local.customer_workload_name}-sso-audit"
    Environment = var.customer_workload_environment
    Purpose     = "sso-audit-logs"
  }
}

resource "aws_s3_bucket_versioning" "sso_audit_bucket_versioning" {
  bucket = aws_s3_bucket.sso_audit_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sso_audit_bucket_encryption" {
  bucket = aws_s3_bucket.sso_audit_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "sso_audit_bucket_pab" {
  bucket = aws_s3_bucket.sso_audit_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SSO Audit Bucket Policy
resource "aws_s3_bucket_policy" "sso_audit_bucket_policy" {
  bucket = aws_s3_bucket.sso_audit_bucket.id

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
        Resource = aws_s3_bucket.sso_audit_bucket.arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:${local.aws_region}:${local.aws_account_id}:trail/${local.customer_workload_name}-sso-audit-trail"
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
        Resource = "${aws_s3_bucket.sso_audit_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "AWS:SourceArn" = "arn:aws:cloudtrail:${local.aws_region}:${local.aws_account_id}:trail/${local.customer_workload_name}-sso-audit-trail"
          }
        }
      }
    ]
  })
}