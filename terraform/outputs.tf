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

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = module.vpc.igw_id
}

############################
# Security Groups
############################
output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "eks_fargate_security_group_id" {
  description = "EKS Fargate security group ID"
  value       = aws_security_group.eks_fargate.id
}

output "documentdb_security_group_id" {
  description = "DocumentDB security group ID"
  value       = aws_security_group.documentdb.id
}

output "vpc_endpoints_security_group_id" {
  description = "VPC Endpoints security group ID"
  value       = aws_security_group.vpc_endpoints.id
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