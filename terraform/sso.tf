############################
# AWS SSO (IDENTITY CENTER)
############################

# NOTE: AWS SSO (Identity Center) must be manually enabled in the AWS Console first
# 1. Go to AWS SSO service in the management account
# 2. Click "Enable AWS SSO"
# 3. Choose "Enable with AWS Organizations"
# 4. Once enabled, uncomment the configuration below

# TODO: Uncomment this configuration after manually enabling AWS SSO
/*
# Get the SSO instance
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

# [Additional SSO configuration would go here...]
*/