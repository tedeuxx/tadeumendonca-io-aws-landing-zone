############################
# AWS
############################
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use (leave empty for CI/CD)"
  type        = string
  default     = ""
}

############################
# Customer Resource Tags
############################
variable "customer_workload_name" {
  description = "AWS Resource Tag - Workload Name"
  type        = string
  default     = "tadeumendonca.io"
  nullable    = false
}

variable "customer_workload_owner" {
  description = "AWS Resource Tag - Workload Owner"
  type        = string
  default     = "tadeu.mendonca"
  nullable    = false
}

variable "customer_workload_sponsor" {
  description = "AWS Resource Tag - Workload Sponsor"
  type        = string
  default     = "tadeu.mendonca"
  nullable    = false
}

variable "customer_workload_environment" {
  description = "AWS Resource Tag - Workload Environment"
  type        = string
  default     = "main"
  nullable    = false
  validation {
    condition     = contains(["main"], var.customer_workload_environment)
    error_message = "valid environments are: main"
  }
}

############################
# Workload Environments
############################
variable "workload_environments" {
  description = "List of environments to deploy workload resources for (e.g., staging, production)"
  type        = list(string)
  default     = []
}

variable "applications" {
  description = "Map of applications with their configuration"
  type = map(object({
    subdomain   = string
    description = string
  }))
  default = {
    webapp = {
      subdomain   = "app"
      description = "Main web application"
    }
    admin = {
      subdomain   = "admin"
      description = "Admin dashboard"
    }
  }
}

variable "documentdb_config" {
  description = "DocumentDB configuration for each environment"
  type = map(object({
    engine_version                         = string
    master_username                        = string
    instance_count                         = number
    instance_class                         = string
    backup_retention                       = number
    preferred_backup_window                = string
    preferred_maintenance_window           = string
    deletion_protection                    = bool
    skip_final_snapshot                    = bool
    cloudwatch_logs                        = list(string)
    create_parameter_group                 = bool
    db_cluster_parameter_group_name        = string
    db_cluster_parameter_group_description = string
    db_cluster_parameter_group_family      = string
    db_cluster_parameter_group_parameters = list(object({
      apply_method = string
      name         = string
      value        = string
    }))
    cluster_tags = map(string)
  }))
  default = {}
}

############################
# DNS & Domain Configuration
############################
variable "root_domain_name" {
  description = "Root domain name for this AWS account (e.g., example.com). Must have a Route53 hosted zone and ACM wildcard certificate configured in the account."
  type        = string
  default     = "tadeumendonca.io"
}

variable "create_cloudfront_distributions" {
  description = "Whether to create CloudFront distributions. Requires ACM certificate to exist."
  type        = bool
  default     = false
}

############################
# EKS Configuration
############################
variable "eks_cluster_version" {
  description = "Kubernetes version for EKS clusters"
  type        = string
  default     = "1.30"
}

variable "enable_eks_cluster_logging" {
  description = "Enable EKS cluster logging"
  type        = bool
  default     = true
}

variable "eks_cluster_log_types" {
  description = "List of EKS cluster log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

############################
# API Gateway Configuration
############################
variable "api_gateway_throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 1000
}

variable "api_gateway_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 2000
}

variable "enable_api_gateway_logging" {
  description = "Enable API Gateway access logging"
  type        = bool
  default     = true
}

variable "enable_api_gateway_xray_tracing" {
  description = "Enable X-Ray tracing for API Gateway"
  type        = bool
  default     = true
}

############################
# WAF Configuration
############################
variable "waf_rate_limit" {
  description = "WAF rate limit for API Gateway (requests per 5 minutes per IP)"
  type        = number
  default     = 1000
}

variable "waf_blocked_countries" {
  description = "List of country codes to block in WAF"
  type        = list(string)
  default     = ["CN", "RU", "KP", "IR"]
}

variable "enable_waf_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = true
}

