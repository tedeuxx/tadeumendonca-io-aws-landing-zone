terraform {
  required_version = ">= 1.0"

  cloud {
    organization = "tadeumendonca-io"
    workspaces {
      name = "aws-landing-zone-main"
    }
  }

  # Previous local backend configuration (migrated to Terraform Cloud)
  # backend "local" {
  #   path = "terraform.tfstate"
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
