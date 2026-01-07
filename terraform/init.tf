terraform {
  required_version = ">= 1.0"

  # Terraform Cloud configuration
  cloud {
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
