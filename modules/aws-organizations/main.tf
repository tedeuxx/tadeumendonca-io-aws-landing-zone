############################
# AWS ORGANIZATIONS MODULE
############################

############################
# AWS ORGANIZATIONS MODULE
############################

# AWS Organizations
resource "aws_organizations_organization" "this" {
  aws_service_access_principals = var.aws_service_access_principals
  feature_set                  = var.feature_set
  enabled_policy_types         = var.enabled_policy_types

  lifecycle {
    prevent_destroy = false  # Temporarily disabled for AWS Support compliance
    ignore_changes = [
      # Ignore changes to these attributes if organization already exists
      aws_service_access_principals,
      feature_set,
      enabled_policy_types
    ]
  }
}

# Organizational Units
resource "aws_organizations_organizational_unit" "this" {
  for_each = var.organizational_units

  name      = each.value.name
  parent_id = each.value.parent_id != null ? each.value.parent_id : aws_organizations_organization.this.roots[0].id

  tags = merge(
    var.default_tags,
    each.value.tags,
    {
      Name = "${each.value.name}-OU"
    }
  )
}

# AWS Accounts
resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name                       = each.value.name
  email                      = each.value.email
  parent_id                 = each.value.parent_ou_key != null ? aws_organizations_organizational_unit.this[each.value.parent_ou_key].id : aws_organizations_organization.this.roots[0].id
  role_name                 = each.value.role_name
  iam_user_access_to_billing = each.value.iam_user_access_to_billing
  close_on_deletion         = each.value.close_on_deletion

  tags = merge(
    var.default_tags,
    each.value.tags,
    {
      Name = "${each.value.name}-Account"
    }
  )

  lifecycle {
    ignore_changes = [role_name]
  }
}

# Service Control Policies
resource "aws_organizations_policy" "this" {
  for_each = var.service_control_policies

  name        = each.value.name
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value.content

  tags = merge(
    var.default_tags,
    each.value.tags,
    {
      Name = "${each.value.name}-SCP"
    }
  )
}

# Policy Attachments
resource "aws_organizations_policy_attachment" "this" {
  for_each = var.policy_attachments

  policy_id = aws_organizations_policy.this[each.value.policy_key].id
  target_id = each.value.target_type == "root" ? aws_organizations_organization.this.roots[0].id : (
    each.value.target_type == "ou" ? aws_organizations_organizational_unit.this[each.value.target_key].id : 
    aws_organizations_account.this[each.value.target_key].id
  )
}

# Organization-wide CloudTrail (optional)
resource "aws_cloudtrail" "organization_trail" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = var.cloudtrail_name
  s3_bucket_name               = var.cloudtrail_s3_bucket_name
  include_global_service_events = var.cloudtrail_include_global_service_events
  is_multi_region_trail        = var.cloudtrail_is_multi_region_trail
  is_organization_trail        = true
  enable_logging               = var.cloudtrail_enable_logging

  dynamic "event_selector" {
    for_each = var.cloudtrail_event_selectors
    content {
      read_write_type                 = event_selector.value.read_write_type
      include_management_events       = event_selector.value.include_management_events
      exclude_management_event_sources = event_selector.value.exclude_management_event_sources

      dynamic "data_resource" {
        for_each = event_selector.value.data_resources
        content {
          type   = data_resource.value.type
          values = data_resource.value.values
        }
      }
    }
  }

  tags = merge(
    var.default_tags,
    var.cloudtrail_tags,
    {
      Name = var.cloudtrail_name
    }
  )
}