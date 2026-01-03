terraform {
  required_version = ">= 1.0"

  cloud {
    # Configure your organization and workspace in Terraform Cloud
    organization = "tadeumendonca-io"
    workspaces {
      name = "aws-landing-zone-main"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
