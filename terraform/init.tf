terraform {
  required_version = ">= 1.0"

  # Temporarily back to local backend while troubleshooting Terraform Cloud
  backend "local" {
    path = "terraform.tfstate"
  }

  # Terraform Cloud configuration (will re-enable once workspace is properly configured)
  # cloud {
  #   organization = "tadeumendonca-io"
  #   workspaces {
  #     name = "aws-landing-zone-main"
  #   }
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
