############################
# IAM POLICIES FOR S3 ACCESS
############################

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ALB service account for access logs (region-specific)
# Reference: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
locals {
  # ELB service account IDs by region
  elb_service_account_id = {
    us-east-1      = "127311923021"
    us-east-2      = "033677994240"
    us-west-1      = "027434742980"
    us-west-2      = "797873946194"
    eu-west-1      = "156460612806"
    eu-central-1   = "054676820928"
    ap-southeast-1 = "114774131450"
    ap-northeast-1 = "582318560864"
  }
}

# S3 bucket policy to allow ALB to write access logs
resource "aws_s3_bucket_policy" "logs_bucket_policy" {
  bucket = module.logs_bucket.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBAccessLogs"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.elb_service_account_id[data.aws_region.current.name]}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${module.logs_bucket.s3_bucket_arn}/alb-access-logs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AllowALBAccessLogsDelivery"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${module.logs_bucket.s3_bucket_arn}/alb-access-logs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AllowALBAccessLogsCheck"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.elb_service_account_id[data.aws_region.current.name]}:root"
        }
        Action   = "s3:GetBucketAcl"
        Resource = module.logs_bucket.s3_bucket_arn
      }
    ]
  })

  depends_on = [module.logs_bucket]
}

# Optional: VPC Flow Logs IAM role (for future use)
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "${local.customer_workload_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${local.customer_workload_name}-vpc-flow-logs-role"
    Environment = var.customer_workload_environment
    Owner       = var.customer_workload_owner
    Purpose     = "vpc-flow-logs"
    Terraform   = "true"
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "${local.customer_workload_name}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          module.logs_bucket.s3_bucket_arn,
          "${module.logs_bucket.s3_bucket_arn}/vpc-flow-logs/*"
        ]
      }
    ]
  })
}