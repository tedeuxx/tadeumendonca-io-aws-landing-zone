terraform {
  required_version = ">= 1.0"

  # Temporarily using local backend to isolate Terraform Cloud issues
  # TODO: Switch back to Terraform Cloud once plan issues are resolved
  backend "local" {
    path = "terraform.tfstate"
  }

  # Original Terraform Cloud configuration (temporarily disabled)
  /*
  cloud {
    organization = "tadeumendonca-io"
    workspaces {
      name = "aws-landing-zone-main"
    }
  }
  */

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
