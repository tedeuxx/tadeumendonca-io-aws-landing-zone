############################
# AWS ORGANIZATIONS OUTPUTS
############################

output "organization_id" {
  description = "The organization ID"
  value       = aws_organizations_organization.this.id
}

output "organization_arn" {
  description = "The organization ARN"
  value       = aws_organizations_organization.this.arn
}

output "organization_master_account_id" {
  description = "The master account ID for the organization"
  value       = aws_organizations_organization.this.master_account_id
}

output "organization_master_account_arn" {
  description = "The master account ARN for the organization"
  value       = aws_organizations_organization.this.master_account_arn
}

output "organization_master_account_email" {
  description = "The master account email for the organization"
  value       = aws_organizations_organization.this.master_account_email
}

output "organization_roots" {
  description = "List of organization roots"
  value       = aws_organizations_organization.this.roots
}

output "organizational_units" {
  description = "Map of organizational units"
  value = {
    for k, v in aws_organizations_organizational_unit.this : k => {
      id   = v.id
      arn  = v.arn
      name = v.name
    }
  }
}

output "accounts" {
  description = "Map of AWS accounts"
  value = {
    for k, v in aws_organizations_account.this : k => {
      id     = v.id
      arn    = v.arn
      name   = v.name
      email  = v.email
      status = v.status
    }
  }
}

output "service_control_policies" {
  description = "Map of Service Control Policies"
  value = {
    for k, v in aws_organizations_policy.this : k => {
      id          = v.id
      arn         = v.arn
      name        = v.name
      description = v.description
      type        = v.type
    }
  }
}

output "cloudtrail_arn" {
  description = "The CloudTrail ARN"
  value       = var.enable_cloudtrail ? aws_cloudtrail.organization_trail[0].arn : null
}

output "cloudtrail_home_region" {
  description = "The region in which the trail was created"
  value       = var.enable_cloudtrail ? aws_cloudtrail.organization_trail[0].home_region : null
}