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