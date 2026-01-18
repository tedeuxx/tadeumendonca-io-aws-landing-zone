aws_region                    = "us-east-1"
aws_profile                   = ""
customer_workload_name        = "tadeumendonca.io"
customer_workload_owner       = "tadeu.mendonca"
customer_workload_sponsor     = "tadeu.mendonca"
customer_workload_environment = "main"

# Workload environments to deploy
workload_environments = ["staging", "production"]

# CloudFront configuration - temporarily disabled pending AWS account verification
create_cloudfront_distributions = false

# Applications configuration with subdomain patterns
applications = {
  webapp = {
    subdomain   = "app"
    description = "Main web application"
  }
}

# EKS Configuration
eks_cluster_version = "1.30"
enable_eks_cluster_logging = true
eks_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# API Gateway Configuration
api_gateway_throttle_rate_limit = 1000
api_gateway_throttle_burst_limit = 2000
enable_api_gateway_logging = true
enable_api_gateway_xray_tracing = true

# WAF Configuration
waf_rate_limit = 1000
waf_blocked_countries = ["CN", "RU", "KP", "IR"]
enable_waf_logging = true

# DocumentDB configuration for all environments
documentdb_config = {
  staging = {
    engine_version                         = "4.0.0"
    master_username                        = "docdb"
    instance_count                         = 1
    instance_class                         = "db.t3.medium"
    backup_retention                       = 3
    preferred_backup_window                = "07:00-09:00"
    preferred_maintenance_window           = "sun:05:00-sun:06:00"
    deletion_protection                    = false
    skip_final_snapshot                    = true
    cloudwatch_logs                        = ["audit"]
    create_parameter_group                 = false
    db_cluster_parameter_group_name        = ""
    db_cluster_parameter_group_description = ""
    db_cluster_parameter_group_family      = ""
    db_cluster_parameter_group_parameters  = []
    cluster_tags                           = {}
  }
  production = {
    engine_version                         = "4.0.0"
    master_username                        = "docdb"
    instance_count                         = 2
    instance_class                         = "db.r5.large"
    backup_retention                       = 7
    preferred_backup_window                = "07:00-09:00"
    preferred_maintenance_window           = "sun:05:00-sun:06:00"
    deletion_protection                    = true
    skip_final_snapshot                    = false
    cloudwatch_logs                        = ["audit", "profiler"]
    create_parameter_group                 = false
    db_cluster_parameter_group_name        = ""
    db_cluster_parameter_group_description = ""
    db_cluster_parameter_group_family      = ""
    db_cluster_parameter_group_parameters  = []
    cluster_tags = {
      Environment = "production"
      Backup      = "required"
    }
  }
}