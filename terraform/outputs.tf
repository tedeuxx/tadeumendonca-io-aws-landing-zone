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

/*
############################
# SSO (Identity Center) - Temporarily disabled
############################
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

/*
############################
# EKS (Temporarily disabled)
############################
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "EKS cluster IAM role name"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}

output "node_groups" {
  description = "EKS node groups"
  value       = module.eks.eks_managed_node_groups
}

output "aws_load_balancer_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  value       = module.aws_load_balancer_controller_irsa_role.iam_role_arn
}

output "cluster_autoscaler_role_arn" {
  description = "Cluster Autoscaler IAM role ARN"
  value       = module.cluster_autoscaler_irsa_role.iam_role_arn
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
output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds_new.id
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