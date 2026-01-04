############################
# AWS
############################
output "aws_region" {
  description = "AWS Region Name"
  value       = local.aws_region
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = local.aws_account_id
}

output "aws_availability_zones" {
  description = "AWS Region Availability Zone Names"
  value       = local.aws_availability_zones
}

############################
# AWS Organizations
############################
output "organization_id" {
  description = "AWS Organization ID"
  value       = module.aws_organizations.organization_id
}

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = module.aws_organizations.organization_arn
}

output "organization_master_account_id" {
  description = "AWS Organization Master Account ID"
  value       = module.aws_organizations.organization_master_account_id
}

output "security_ou_id" {
  description = "Security Organizational Unit ID"
  value       = module.aws_organizations.organizational_units["security"].id
}

output "staging_ou_id" {
  description = "Staging Organizational Unit ID"
  value       = module.aws_organizations.organizational_units["staging"].id
}

output "production_ou_id" {
  description = "Production Organizational Unit ID"
  value       = module.aws_organizations.organizational_units["production"].id
}

output "security_account_id" {
  description = "Security Account ID"
  value       = module.aws_organizations.accounts["security"].id
}

output "log_archive_account_id" {
  description = "Log Archive Account ID"
  value       = module.aws_organizations.accounts["log_archive"].id
}

output "audit_account_id" {
  description = "Audit Account ID"
  value       = module.aws_organizations.accounts["audit"].id
}

output "cloudtrail_bucket_name" {
  description = "Organization CloudTrail S3 Bucket Name"
  value       = aws_s3_bucket.cloudtrail_bucket.bucket
}

############################
# AFT (Account Factory for Terraform)
############################
output "aft_account_requests_bucket_name" {
  description = "AFT Account Requests S3 Bucket Name"
  value       = aws_s3_bucket.aft_account_requests.bucket
}

output "aft_account_provisioning_role_arn" {
  description = "AFT Account Provisioning Role ARN"
  value       = aws_iam_role.aft_account_provisioning_role.arn
}

############################
# SSO (Identity Center)
############################
output "sso_status" {
  description = "AWS SSO Status"
  value       = "AWS SSO must be manually enabled in the console before deploying this configuration"
}

# TODO: Uncomment these outputs after enabling SSO and uncommenting SSO resources
/*
output "sso_instance_arn" {
  description = "AWS SSO Instance ARN"
  value       = local.sso_instance_arn
}

output "identity_store_id" {
  description = "AWS SSO Identity Store ID"
  value       = local.identity_store_id
}

output "organization_admin_permission_set_arn" {
  description = "Organization Admin Permission Set ARN"
  value       = aws_ssoadmin_permission_set.organization_admin.arn
}

output "production_admin_permission_set_arn" {
  description = "Production Admin Permission Set ARN"
  value       = aws_ssoadmin_permission_set.production_admin.arn
}

output "developer_access_permission_set_arn" {
  description = "Developer Access Permission Set ARN"
  value       = aws_ssoadmin_permission_set.developer_access.arn
}

output "read_only_permission_set_arn" {
  description = "Read Only Permission Set ARN"
  value       = aws_ssoadmin_permission_set.read_only.arn
}

output "sso_audit_bucket_name" {
  description = "SSO Audit S3 Bucket Name"
  value       = aws_s3_bucket.sso_audit_bucket.bucket
}
*/

############################
# VPC
############################
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnets
}

output "database_subnet_group_name" {
  description = "Database subnet group name"
  value       = module.vpc.database_subnet_group_name
}

############################
# Security Groups
############################
output "eks_control_plane_security_group_id" {
  description = "EKS control plane security group ID"
  value       = aws_security_group.eks_control_plane.id
}

output "eks_worker_nodes_security_group_id" {
  description = "EKS worker nodes security group ID"
  value       = aws_security_group.eks_worker_nodes.id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

############################
# S3 Buckets
############################
output "assets_bucket_id" {
  description = "Assets S3 bucket ID"
  value       = module.assets_bucket.s3_bucket_id
}

output "assets_bucket_arn" {
  description = "Assets S3 bucket ARN"
  value       = module.assets_bucket.s3_bucket_arn
}

output "backups_bucket_id" {
  description = "Backups S3 bucket ID"
  value       = module.backups_bucket.s3_bucket_id
}

output "backups_bucket_arn" {
  description = "Backups S3 bucket ARN"
  value       = module.backups_bucket.s3_bucket_arn
}

############################
# Customer Resource Tags
############################
output "customer_workload_name" {
  description = "Workload Name"
  value       = local.customer_workload_name
}