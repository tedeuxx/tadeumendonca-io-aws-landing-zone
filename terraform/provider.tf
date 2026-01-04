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

# AWS Provider for SSO resources (must be us-east-1)
provider "aws" {
  alias  = "sso"
  region = "us-east-1"
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