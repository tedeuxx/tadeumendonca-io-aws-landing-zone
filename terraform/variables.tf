############################
# AWS
############################
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "sa-east-1"
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
  nullable    = false
}

variable "customer_workload_owner" {
  description = "AWS Resource Tag - Workload Owner"
  type        = string
  nullable    = false
}

variable "customer_workload_sponsor" {
  description = "AWS Resource Tag - Workload Sponsor"
  type        = string
  nullable    = false
}

variable "customer_workload_environment" {
  description = "AWS Resource Tag - Workload Environment"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["main"], var.customer_workload_environment)
    error_message = "valid environments are: main"
  }
}

############################
# SSO VARIABLES
############################

variable "sso_admin_user_id" {
  description = "SSO User ID for organization admin access"
  type        = string
  default     = "" # Will be populated after SSO user creation
}

variable "sso_readonly_group_id" {
  description = "SSO Group ID for read-only access"
  type        = string
  default     = "" # Will be populated after SSO group creation
}

############################
# EKS VARIABLES
############################

variable "eks_node_ssh_key_name" {
  description = "EC2 Key Pair name for EKS node SSH access (optional)"
  type        = string
  default     = ""
}