############################
# AWS ACCOUNT DATA SOURCES
############################
# Get the account id from the profile being used to deploy the terraform
data "aws_caller_identity" "current" {}

# Get current region from the profile being used to deploy terraform
data "aws_region" "current" {}

# Get current AWS partition
data "aws_partition" "current" {}

# Get AZs for region
data "aws_availability_zones" "azs" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

############################
# ROUTE53 DATA SOURCES
############################

# Data source for the existing hosted zone
data "aws_route53_zone" "main" {
  name         = var.root_domain_name
  private_zone = false
}

############################
# ACM DATA SOURCES
############################

# Data source for existing ACM certificate (must be in us-east-1 for CloudFront)
data "aws_acm_certificate" "main" {
  provider    = aws.us_east_1
  domain      = var.root_domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

############################
# IAM POLICY DOCUMENTS
############################

# IAM policy document for CloudFront OAC access to S3
data "aws_iam_policy_document" "frontend_cloudfront" {
  for_each = var.create_cloudfront_distributions ? local.app_env_combinations : {}

  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${module.frontend_bucket[each.key].s3_bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront[each.key].cloudfront_distribution_arn]
    }
  }
}