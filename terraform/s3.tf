# Frontend S3 buckets for static hosting
# Uses FQDN as bucket name for each application per environment
# Creates per-application, per-environment infrastructure

# S3 buckets for frontend static assets (private buckets)
# Bucket name matches the FQDN for the frontend application
module "frontend_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  for_each = local.app_env_combinations

  bucket = each.value.fqdn

  # Disable versioning for cost optimization
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

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = merge(local.common_tags, {
    Name        = each.value.fqdn
    Environment = each.value.environment
    Application = each.value.app_name
    FQDN        = each.value.fqdn
    Purpose     = "${each.value.environment}-${each.value.app_name}-frontend-hosting"
  })
}

# Upload test HTML file to frontend buckets
resource "aws_s3_object" "index_html" {
  for_each = local.app_env_combinations

  bucket = module.frontend_bucket[each.key].s3_bucket_id
  key    = "index.html"
  source = "../test-frontend/index.html"

  # Content type for HTML files
  content_type = "text/html"

  # ETag to detect file changes
  etag = filemd5("../test-frontend/index.html")

  tags = {
    Name        = "index.html"
    Environment = each.value.environment
    Application = each.value.app_name
    Purpose     = "test-frontend-file"
  }
}