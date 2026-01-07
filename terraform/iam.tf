############################
# IAM POLICIES FOR S3 ACCESS
############################

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
          AWS = "arn:aws:iam::${local.elb_service_account_id[local.aws_region]}:root"
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
          AWS = "arn:aws:iam::${local.elb_service_account_id[local.aws_region]}:root"
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