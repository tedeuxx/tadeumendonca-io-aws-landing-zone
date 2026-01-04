############################
# AWS ORGANIZATIONS VARIABLES
############################

variable "aws_service_access_principals" {
  description = "List of AWS service principals that you want to enable integration with your organization"
  type        = list(string)
  default = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "account.amazonaws.com"
  ]
}

variable "feature_set" {
  description = "Specify ALL or CONSOLIDATED_BILLING"
  type        = string
  default     = "ALL"
  validation {
    condition     = contains(["ALL", "CONSOLIDATED_BILLING"], var.feature_set)
    error_message = "Feature set must be either ALL or CONSOLIDATED_BILLING."
  }
}

variable "enabled_policy_types" {
  description = "List of Organizations policy types to enable in the Organization Root"
  type        = list(string)
  default = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]
}

variable "organizational_units" {
  description = "Map of organizational units to create"
  type = map(object({
    name      = string
    parent_id = optional(string)
    tags      = optional(map(string), {})
  }))
  default = {}
}

variable "accounts" {
  description = "Map of AWS accounts to create"
  type = map(object({
    name                       = string
    email                      = string
    parent_ou_key             = optional(string)
    role_name                 = optional(string, "OrganizationAccountAccessRole")
    iam_user_access_to_billing = optional(string, "ALLOW")
    close_on_deletion         = optional(bool, false)
    tags                      = optional(map(string), {})
  }))
  default = {}
}

variable "service_control_policies" {
  description = "Map of Service Control Policies to create"
  type = map(object({
    name        = string
    description = string
    content     = string
    tags        = optional(map(string), {})
  }))
  default = {}
}

variable "policy_attachments" {
  description = "Map of policy attachments"
  type = map(object({
    policy_key  = string
    target_type = string # "root", "ou", or "account"
    target_key  = optional(string) # Required for "ou" and "account" types
  }))
  default = {}
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

############################
# CLOUDTRAIL VARIABLES
############################

variable "enable_cloudtrail" {
  description = "Whether to create an organization-wide CloudTrail"
  type        = bool
  default     = false
}

variable "cloudtrail_name" {
  description = "Name of the CloudTrail"
  type        = string
  default     = "organization-trail"
}

variable "cloudtrail_s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail logs"
  type        = string
  default     = ""
}

variable "cloudtrail_include_global_service_events" {
  description = "Whether to include global service events"
  type        = bool
  default     = true
}

variable "cloudtrail_is_multi_region_trail" {
  description = "Whether the trail is a multi-region trail"
  type        = bool
  default     = true
}

variable "cloudtrail_enable_logging" {
  description = "Whether to enable logging for the trail"
  type        = bool
  default     = true
}

variable "cloudtrail_event_selectors" {
  description = "List of event selectors for CloudTrail"
  type = list(object({
    read_write_type                 = optional(string, "All")
    include_management_events       = optional(bool, true)
    exclude_management_event_sources = optional(list(string), [])
    data_resources = optional(list(object({
      type   = string
      values = list(string)
    })), [])
  }))
  default = []
}

variable "cloudtrail_tags" {
  description = "Tags to apply to CloudTrail"
  type        = map(string)
  default     = {}
}