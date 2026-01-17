# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  # Use profile only for local development, CI uses environment variables
  profile = var.aws_profile != "" ? var.aws_profile : null
  default_tags {
    tags = {
      customer_workload_name        = var.customer_workload_name
      customer_workload_owner       = var.customer_workload_owner
      customer_workload_sponsor     = var.customer_workload_sponsor
      customer_workload_environment = var.customer_workload_environment
    }
  }
}

# AWS provider alias for us-east-1 (required for ACM certificates with CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  # Use profile only for local development, CI uses environment variables
  profile = var.aws_profile != "" ? var.aws_profile : null
}