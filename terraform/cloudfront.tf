# CloudFront distributions for frontend SPA hosting
# Uses S3 private buckets with Origin Access Control (OAC) for security

# CloudFront distribution for each application in each environment
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 6.2"

  for_each = var.create_cloudfront_distributions ? local.app_env_combinations : {}

  comment             = "${each.value.fqdn} frontend distribution"
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Custom domain configuration
  aliases = [each.value.fqdn]

  # Origin Access Control configuration
  origin_access_control = {
    s3 = {
      description      = "CloudFront access to ${each.value.fqdn} S3 bucket"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  # S3 origin configuration
  origin = {
    s3_frontend = {
      domain_name               = module.frontend_bucket[each.key].s3_bucket_bucket_regional_domain_name
      origin_access_control_key = "s3" # key in origin_access_control above
    }
  }

  # Cache behavior for frontend SPA (default)
  default_cache_behavior = {
    target_origin_id       = "s3_frontend"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values = {
      query_string = false
      cookies = {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600  # 1 hour
    max_ttl     = 86400 # 24 hours
  }

  # Custom error pages for SPA routing
  custom_error_response = [
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    },
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    }
  ]

  # Geographic restrictions (none for now)
  restrictions = {
    geo_restriction = {
      restriction_type = "none"
    }
  }

  # SSL certificate configuration
  viewer_certificate = {
    acm_certificate_arn      = data.aws_acm_certificate.main.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # WAF Web ACL association
  web_acl_id = var.create_cloudfront_distributions ? aws_wafv2_web_acl.cloudfront[0].arn : null

  tags = merge(local.common_tags, {
    Name        = each.value.fqdn
    Environment = each.value.environment
    Application = each.value.app_name
    FQDN        = each.value.fqdn
    Purpose     = "${each.value.environment}-${each.value.app_name}-frontend-distribution"
  })
}

# S3 bucket policy to allow CloudFront OAC access
# Created as separate resource to avoid circular dependency
resource "aws_s3_bucket_policy" "frontend_cloudfront" {
  for_each = var.create_cloudfront_distributions ? local.app_env_combinations : {}

  bucket = module.frontend_bucket[each.key].s3_bucket_id
  policy = data.aws_iam_policy_document.frontend_cloudfront[each.key].json
}