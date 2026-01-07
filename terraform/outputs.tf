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

output "logs_bucket_id" {
  description = "Logs S3 bucket ID"
  value       = module.logs_bucket.s3_bucket_id
}

output "logs_bucket_arn" {
  description = "Logs S3 bucket ARN"
  value       = module.logs_bucket.s3_bucket_arn
}

############################
# DocumentDB
############################
output "documentdb_cluster_endpoints" {
  description = "DocumentDB cluster endpoints by environment"
  value = {
    for env in var.workload_environments :
    env => module.documentdb[env].cluster_endpoint
  }
}

output "documentdb_cluster_reader_endpoints" {
  description = "DocumentDB cluster reader endpoints by environment"
  value = {
    for env in var.workload_environments :
    env => module.documentdb[env].cluster_reader_endpoint
  }
}

output "documentdb_cluster_ids" {
  description = "DocumentDB cluster IDs by environment"
  value = {
    for env in var.workload_environments :
    env => module.documentdb[env].cluster_id
  }
}

output "documentdb_cluster_ports" {
  description = "DocumentDB cluster ports by environment"
  value = {
    for env in var.workload_environments :
    env => module.documentdb[env].cluster_port
  }
}

############################
# IAM
############################
output "vpc_flow_logs_role_arn" {
  description = "VPC Flow Logs IAM role ARN"
  value       = aws_iam_role.vpc_flow_logs_role.arn
}

############################
# Customer Resource Tags
############################
output "customer_workload_name" {
  description = "Workload Name"
  value       = local.customer_workload_name
}