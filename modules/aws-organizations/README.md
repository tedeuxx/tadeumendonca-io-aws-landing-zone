# AWS Organizations Terraform Module

This module creates and manages AWS Organizations with organizational units, accounts, service control policies, and optional CloudTrail integration.

## Features

- ✅ **AWS Organizations** with configurable feature set
- ✅ **Organizational Units (OUs)** with hierarchical structure
- ✅ **AWS Accounts** with automatic placement in OUs
- ✅ **Service Control Policies (SCPs)** with flexible attachment
- ✅ **Organization-wide CloudTrail** (optional)
- ✅ **Comprehensive tagging** support
- ✅ **Flexible configuration** via variables

## Usage

### Basic Example

```hcl
module "aws_organizations" {
  source = "./modules/aws-organizations"

  organizational_units = {
    security = {
      name = "Security"
    }
    production = {
      name = "Production"
    }
  }

  accounts = {
    security = {
      name          = "Security Account"
      email         = "security@example.com"
      parent_ou_key = "security"
    }
    production = {
      name          = "Production Account"
      email         = "production@example.com"
      parent_ou_key = "production"
    }
  }

  default_tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
```

### Advanced Example with SCPs and CloudTrail

```hcl
module "aws_organizations" {
  source = "./modules/aws-organizations"

  # Organizational Units
  organizational_units = {
    security = {
      name = "Security"
      tags = {
        Purpose = "security-accounts"
      }
    }
    development = {
      name = "Development"
      tags = {
        Purpose = "development-accounts"
      }
    }
    production = {
      name = "Production"
      tags = {
        Purpose = "production-accounts"
      }
    }
  }

  # AWS Accounts
  accounts = {
    security = {
      name          = "Security Account"
      email         = "security@example.com"
      parent_ou_key = "security"
    }
    log_archive = {
      name          = "Log Archive Account"
      email         = "log-archive@example.com"
      parent_ou_key = "security"
    }
    dev = {
      name          = "Development Account"
      email         = "dev@example.com"
      parent_ou_key = "development"
    }
    prod = {
      name          = "Production Account"
      email         = "prod@example.com"
      parent_ou_key = "production"
    }
  }

  # Service Control Policies
  service_control_policies = {
    baseline_security = {
      name        = "BaselineSecurityPolicy"
      description = "Baseline security controls for all accounts"
      content = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "DenyLeavingOrganization"
            Effect = "Deny"
            Action = [
              "organizations:LeaveOrganization",
              "account:CloseAccount"
            ]
            Resource = "*"
          }
        ]
      })
    }
  }

  # Policy Attachments
  policy_attachments = {
    baseline_to_root = {
      policy_key  = "baseline_security"
      target_type = "root"
    }
  }

  # CloudTrail
  enable_cloudtrail                = true
  cloudtrail_name                 = "organization-trail"
  cloudtrail_s3_bucket_name       = "my-org-cloudtrail-bucket"
  cloudtrail_event_selectors = [
    {
      data_resources = [
        {
          type   = "AWS::S3::Object"
          values = ["arn:aws:s3:::*/*"]
        }
      ]
    }
  ]

  default_tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "aws-landing-zone"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_service_access_principals | List of AWS service principals for organization integration | `list(string)` | `["cloudtrail.amazonaws.com", "config.amazonaws.com", "sso.amazonaws.com", "account.amazonaws.com"]` | no |
| feature_set | Specify ALL or CONSOLIDATED_BILLING | `string` | `"ALL"` | no |
| enabled_policy_types | List of Organizations policy types to enable | `list(string)` | `["SERVICE_CONTROL_POLICY", "TAG_POLICY"]` | no |
| organizational_units | Map of organizational units to create | `map(object)` | `{}` | no |
| accounts | Map of AWS accounts to create | `map(object)` | `{}` | no |
| service_control_policies | Map of Service Control Policies to create | `map(object)` | `{}` | no |
| policy_attachments | Map of policy attachments | `map(object)` | `{}` | no |
| default_tags | Default tags to apply to all resources | `map(string)` | `{}` | no |
| enable_cloudtrail | Whether to create organization-wide CloudTrail | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| organization_id | The organization ID |
| organization_arn | The organization ARN |
| organization_master_account_id | The master account ID |
| organizational_units | Map of organizational units with IDs and ARNs |
| accounts | Map of AWS accounts with IDs and ARNs |
| service_control_policies | Map of Service Control Policies |
| cloudtrail_arn | The CloudTrail ARN (if enabled) |

## Notes

- **Account Creation**: Account creation can take several minutes per account
- **Email Addresses**: Each account requires a unique email address
- **Permissions**: Must be run from the management account with appropriate IAM permissions
- **SCPs**: Service Control Policies are inherited by child OUs and accounts
- **CloudTrail**: Organization trail requires a pre-existing S3 bucket with proper policies

## License

This module is released under the MIT License. See LICENSE for more information.