############################
# AWS SSO (IDENTITY CENTER)
############################

# TODO: Temporarily disabled SSO to isolate terraform plan issues
# Will re-enable once base infrastructure is stable

# Temporary: S3 bucket for cleanup (force destroy to handle non-empty bucket)
resource "aws_s3_bucket" "sso_audit_bucket" {
  bucket        = "${local.customer_workload_name}-sso-audit-${random_id.bucket_suffix.hex}"
  force_destroy = true # Allow deletion even when not empty

  tags = {
    Name        = "${local.customer_workload_name}-sso-audit"
    Environment = var.customer_workload_environment
    Purpose     = "sso-audit-logs"
  }
}