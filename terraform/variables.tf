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

