############################
# AWS ACCOUNT FACTORY FOR TERRAFORM (AFT)
############################

# AFT requires Control Tower to be enabled first
# This will be deployed in the management account

# AFT Management Infrastructure - TEMPORARILY DISABLED
# TODO: Re-enable after resolving provider version conflicts with AWS provider >= 6.0.0
# The AFT module requires AWS provider >= 6.0.0 which conflicts with our current ~> 5.0 constraint
/*
module "aft" {
  source = "github.com/aws-ia/terraform-aws-control_tower_account_factory"

  # AFT Configuration
  ct_management_account_id  = local.aws_account_id
  log_archive_account_id    = module.aws_organizations.accounts["log_archive"].id
  audit_account_id          = module.aws_organizations.accounts["audit"].id
  aft_management_account_id = local.aws_account_id # Using management account for AFT

  # GitHub Integration for Account Requests
  vcs_provider                                  = "github"
  account_request_repo_name                     = "${var.customer_workload_owner}/aft-account-request"
  global_customizations_repo_name               = "${var.customer_workload_owner}/aft-global-customizations"
  account_customizations_repo_name              = "${var.customer_workload_owner}/aft-account-customizations"
  account_provisioning_customizations_repo_name = "${var.customer_workload_owner}/aft-account-provisioning-customizations"

  # AFT Backend Configuration
  aft_backend_bucket_name = "${local.customer_workload_name}-aft-backend-${random_id.bucket_suffix.hex}"

  # Terraform Distribution
  terraform_version      = "1.5.7"
  terraform_distribution = "oss"

  # CloudWatch Log Groups
  cloudwatch_log_group_retention = 14

  # AFT Feature Flags
  aft_enable_vpc = true

  # Maximum concurrent account customizations
  maximum_concurrent_customizations = 5

  # AFT VPC Configuration
  aft_vpc_cidr            = "192.168.0.0/22"
  aft_vpc_private_subnets = ["192.168.0.0/24", "192.168.1.0/24"]
  aft_vpc_public_subnets  = ["192.168.2.0/24", "192.168.3.0/24"]

  # Tags
  tags = {
    Environment = var.customer_workload_environment
    Owner       = var.customer_workload_owner
    Project     = "aws-landing-zone"
    Component   = "account-factory"
  }
}
*/

# S3 Bucket for AFT Account Requests (if using S3 instead of GitHub)
resource "aws_s3_bucket" "aft_account_requests" {
  bucket        = "${local.customer_workload_name}-aft-requests-${random_id.bucket_suffix.hex}"
  force_destroy = false

  tags = {
    Name        = "${local.customer_workload_name}-aft-requests"
    Environment = var.customer_workload_environment
    Purpose     = "aft-account-requests"
  }
}

resource "aws_s3_bucket_versioning" "aft_account_requests_versioning" {
  bucket = aws_s3_bucket.aft_account_requests.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aft_account_requests_encryption" {
  bucket = aws_s3_bucket.aft_account_requests.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "aft_account_requests_pab" {
  bucket = aws_s3_bucket.aft_account_requests.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for AFT Account Provisioning
resource "aws_iam_role" "aft_account_provisioning_role" {
  name = "${local.customer_workload_name}-aft-account-provisioning-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "codebuild.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = {
    Name        = "${local.customer_workload_name}-aft-account-provisioning-role"
    Environment = var.customer_workload_environment
    Purpose     = "aft-account-provisioning"
  }
}

# IAM Policy for AFT Account Provisioning
resource "aws_iam_role_policy" "aft_account_provisioning_policy" {
  name = "${local.customer_workload_name}-aft-account-provisioning-policy"
  role = aws_iam_role.aft_account_provisioning_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "organizations:*",
          "account:*",
          "iam:*",
          "sts:*",
          "s3:*",
          "lambda:*",
          "logs:*",
          "events:*",
          "codebuild:*",
          "codepipeline:*",
          "ssm:*"
        ]
        Resource = "*"
      }
    ]
  })
}