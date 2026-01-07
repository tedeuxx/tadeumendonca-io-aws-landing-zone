############################
# MAIN INFRASTRUCTURE
############################

# S3 Buckets for application assets and backups
module "assets_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${local.aws_account_id}-${local.customer_workload_name}-assets"

  # Versioning
  versioning = {
    enabled = false
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Lifecycle configuration
  lifecycle_rule = [
    {
      id     = "assets_lifecycle"
      status = "Enabled"

      filter = {
        prefix = ""
      }

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 365
      }
    }
  ]

  # Block public access (will be configured for CloudFront later)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Name        = "${local.customer_workload_name}-assets"
    Environment = var.customer_workload_environment
    Owner       = var.customer_workload_owner
    Purpose     = "application-assets"
    Terraform   = "true"
  }
}

module "backups_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${local.aws_account_id}-${local.customer_workload_name}-backups"

  # Versioning
  versioning = {
    enabled = false
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Lifecycle configuration
  lifecycle_rule = [
    {
      id     = "backups_lifecycle"
      status = "Enabled"

      filter = {
        prefix = ""
      }

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 180
          storage_class = "DEEP_ARCHIVE"
        }
      ]

      expiration = {
        days = 2555 # 7 years retention
      }
    }
  ]

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Name        = "${local.customer_workload_name}-backups"
    Environment = var.customer_workload_environment
    Owner       = var.customer_workload_owner
    Purpose     = "application-backups"
    Terraform   = "true"
  }
}