############################
# MAIN INFRASTRUCTURE
############################

# Random ID for resource naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Buckets for application assets and backups
module "assets_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${local.customer_workload_name}-assets-${random_id.bucket_suffix.hex}"

  # Versioning
  versioning = {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

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

# Separate lifecycle configuration for assets bucket
resource "aws_s3_bucket_lifecycle_configuration" "assets_bucket_lifecycle" {
  bucket = module.assets_bucket.s3_bucket_id

  rule {
    id     = "intelligent_tiering"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Separate intelligent tiering configuration for assets bucket
resource "aws_s3_bucket_intelligent_tiering_configuration" "assets_bucket_tiering" {
  bucket = module.assets_bucket.s3_bucket_id
  name   = "EntireBucket"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

module "backups_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${local.customer_workload_name}-backups-${random_id.bucket_suffix.hex}"

  # Versioning
  versioning = {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

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

# Separate lifecycle configuration for backups bucket
resource "aws_s3_bucket_lifecycle_configuration" "backups_bucket_lifecycle" {
  bucket = module.backups_bucket.s3_bucket_id

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2555 # 7 years retention
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}