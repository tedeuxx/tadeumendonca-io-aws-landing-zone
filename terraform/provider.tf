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

# Kubernetes provider configuration
# Note: This uses a data source approach to avoid circular dependencies
provider "kubernetes" {
  host                   = try(module.eks[var.workload_environments[0]].cluster_endpoint, "")
  cluster_ca_certificate = try(base64decode(module.eks[var.workload_environments[0]].cluster_certificate_authority_data), "")

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      try(module.eks[var.workload_environments[0]].cluster_name, ""),
      "--region",
      var.aws_region,
    ]
  }
}

# Helm provider configuration
provider "helm" {
  kubernetes {
    host                   = try(module.eks[var.workload_environments[0]].cluster_endpoint, "")
    cluster_ca_certificate = try(base64decode(module.eks[var.workload_environments[0]].cluster_certificate_authority_data), "")

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        try(module.eks[var.workload_environments[0]].cluster_name, ""),
        "--region",
        var.aws_region,
      ]
    }
  }
}