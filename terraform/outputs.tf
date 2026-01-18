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
  description = "VPC Flow Logs IAM role ARN (managed by VPC module)"
  value       = module.vpc.vpc_flow_log_cloudwatch_iam_role_arn
}

############################
# Customer Resource Tags
############################
output "customer_workload_name" {
  description = "Workload Name"
  value       = local.customer_workload_name
}

############################
# Frontend S3 Buckets
############################
output "frontend_bucket_ids" {
  description = "Frontend S3 bucket IDs by application and environment"
  value = {
    for key, combo in local.app_env_combinations :
    key => module.frontend_bucket[key].s3_bucket_id
  }
}

output "frontend_bucket_arns" {
  description = "Frontend S3 bucket ARNs by application and environment"
  value = {
    for key, combo in local.app_env_combinations :
    key => module.frontend_bucket[key].s3_bucket_arn
  }
}

output "frontend_bucket_domains" {
  description = "Frontend S3 bucket regional domain names by application and environment"
  value = {
    for key, combo in local.app_env_combinations :
    key => module.frontend_bucket[key].s3_bucket_bucket_regional_domain_name
  }
}

output "application_fqdns" {
  description = "FQDN to S3 bucket mapping for applications"
  value = {
    for key, combo in local.app_env_combinations :
    combo.fqdn => {
      s3_bucket_name = module.frontend_bucket[key].s3_bucket_id
      application    = combo.app_name
      environment    = combo.environment
    }
  }
}

output "frontend_test_urls" {
  description = "Test URLs for frontend applications"
  value = {
    for key, combo in local.app_env_combinations :
    combo.fqdn => {
      s3_website_url    = "http://${module.frontend_bucket[key].s3_bucket_id}.s3-website-${data.aws_region.current.id}.amazonaws.com"
      s3_object_url     = "https://${module.frontend_bucket[key].s3_bucket_bucket_regional_domain_name}/index.html"
      cloudfront_url    = var.create_cloudfront_distributions ? "https://${module.cloudfront[key].cloudfront_distribution_domain_name}" : "CloudFront disabled"
      cloudfront_domain = var.create_cloudfront_distributions ? module.cloudfront[key].cloudfront_distribution_domain_name : "CloudFront disabled"
    }
  }
}

############################
# CloudFront
############################
output "cloudfront_distribution_ids" {
  description = "CloudFront distribution IDs by application and environment"
  value = var.create_cloudfront_distributions ? {
    for key, combo in local.app_env_combinations :
    key => module.cloudfront[key].cloudfront_distribution_id
  } : {}
}

output "cloudfront_distribution_arns" {
  description = "CloudFront distribution ARNs by application and environment"
  value = var.create_cloudfront_distributions ? {
    for key, combo in local.app_env_combinations :
    key => module.cloudfront[key].cloudfront_distribution_arn
  } : {}
}

output "cloudfront_domain_names" {
  description = "CloudFront distribution domain names by application and environment"
  value = var.create_cloudfront_distributions ? {
    for key, combo in local.app_env_combinations :
    key => module.cloudfront[key].cloudfront_distribution_domain_name
  } : {}
}

############################
# Route53 & DNS
############################
output "route53_zone_id" {
  description = "Route53 hosted zone ID for tadeumendonca.io"
  value       = data.aws_route53_zone.main.zone_id
}

output "route53_records" {
  description = "Route53 DNS records for frontend applications"
  value = {
    for key, combo in local.app_env_combinations :
    combo.fqdn => {
      name    = combo.fqdn
      type    = "A"
      zone_id = data.aws_route53_zone.main.zone_id
    }
  }
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN used for CloudFront"
  value       = data.aws_acm_certificate.main.arn
}

############################
# WAF
############################
output "waf_web_acl_id" {
  description = "WAF Web ACL ID for CloudFront protection"
  value       = var.create_cloudfront_distributions ? aws_wafv2_web_acl.cloudfront[0].id : null
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN for CloudFront protection"
  value       = var.create_cloudfront_distributions ? aws_wafv2_web_acl.cloudfront[0].arn : null
}

output "waf_cloudwatch_log_group" {
  description = "CloudWatch log group for WAF logs"
  value       = var.create_cloudfront_distributions ? aws_cloudwatch_log_group.waf_cloudfront[0].name : null
}

############################
# EKS CLUSTERS
############################
output "eks_cluster_ids" {
  description = "EKS cluster IDs by environment"
  value = {
    for env in var.workload_environments :
    env => module.eks[env].cluster_id
  }
}

output "eks_cluster_arns" {
  description = "EKS cluster ARNs by environment"
  value = {
    for env in var.workload_environments :
    env => module.eks[env].cluster_arn
  }
}

output "eks_cluster_endpoints" {
  description = "EKS cluster endpoints by environment"
  value = {
    for env in var.workload_environments :
    env => module.eks[env].cluster_endpoint
  }
  sensitive = true
}

output "eks_cluster_versions" {
  description = "EKS cluster Kubernetes versions by environment"
  value = {
    for env in var.workload_environments :
    env => module.eks[env].cluster_version
  }
}

output "eks_cluster_security_group_ids" {
  description = "EKS cluster security group IDs by environment"
  value = {
    for env in var.workload_environments :
    env => module.eks[env].cluster_security_group_id
  }
}

output "eks_oidc_provider_arns" {
  description = "EKS OIDC provider ARNs by environment"
  value = {
    for env in var.workload_environments :
    env => module.eks[env].oidc_provider_arn
  }
}

output "eks_fargate_profile_arns" {
  description = "EKS Fargate profile ARNs by environment"
  value = {
    for env in var.workload_environments :
    env => module.eks[env].fargate_profiles
  }
}

############################
# API GATEWAY
############################
output "api_gateway_rest_api_ids" {
  description = "API Gateway REST API IDs by environment"
  value = {
    for env in var.workload_environments :
    env => aws_api_gateway_rest_api.main[env].id
  }
}

output "api_gateway_rest_api_root_resource_ids" {
  description = "API Gateway REST API root resource IDs by environment"
  value = {
    for env in var.workload_environments :
    env => aws_api_gateway_rest_api.main[env].root_resource_id
  }
}

output "api_gateway_stage_arns" {
  description = "API Gateway stage ARNs by environment"
  value = {
    for env in var.workload_environments :
    env => aws_api_gateway_stage.main[env].arn
  }
}

output "api_gateway_invoke_urls" {
  description = "API Gateway invoke URLs by environment"
  value = {
    for env in var.workload_environments :
    env => aws_api_gateway_stage.main[env].invoke_url
  }
}

output "api_gateway_custom_domain_names" {
  description = "API Gateway custom domain names by environment"
  value = {
    for env in var.workload_environments :
    env => aws_api_gateway_domain_name.main[env].domain_name
  }
}

output "api_domain_names" {
  description = "API domain names by environment"
  value       = local.api_domain_names
}

############################
# VPC LINKS
############################
output "vpc_link_ids" {
  description = "VPC Link IDs by environment"
  value = {
    for env in var.workload_environments :
    env => aws_api_gateway_vpc_link.main[env].id
  }
}

output "vpc_link_names" {
  description = "VPC Link names by environment"
  value = {
    for env in var.workload_environments :
    env => aws_api_gateway_vpc_link.main[env].name
  }
}

############################
# WAF API GATEWAY
############################
output "waf_api_gateway_web_acl_ids" {
  description = "WAF Web ACL IDs for API Gateway protection by environment"
  value = {
    for env in var.workload_environments :
    env => aws_wafv2_web_acl.api_gateway[env].id
  }
}

output "waf_api_gateway_web_acl_arns" {
  description = "WAF Web ACL ARNs for API Gateway protection by environment"
  value = {
    for env in var.workload_environments :
    env => aws_wafv2_web_acl.api_gateway[env].arn
  }
}

output "waf_api_gateway_cloudwatch_log_groups" {
  description = "CloudWatch log groups for WAF API Gateway logs by environment"
  value = {
    for env in var.workload_environments :
    env => aws_cloudwatch_log_group.waf_api_gateway[env].name
  }
}

############################
# KUBERNETES NAMESPACES
############################
output "kubernetes_namespaces" {
  description = "Kubernetes namespace names by environment"
  value = {
    for env in var.workload_environments :
    env => kubernetes_namespace.application[env].metadata[0].name
  }
}

############################
# CLOUDWATCH LOG GROUPS
############################
output "eks_fargate_log_groups" {
  description = "CloudWatch log groups for EKS Fargate logs by environment"
  value = {
    for env in var.workload_environments :
    env => aws_cloudwatch_log_group.fargate[env].name
  }
}

output "api_gateway_log_groups" {
  description = "CloudWatch log groups for API Gateway logs by environment"
  value = {
    for env in var.workload_environments :
    env => aws_cloudwatch_log_group.api_gateway[env].name
  }
}