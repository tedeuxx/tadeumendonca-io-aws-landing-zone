# AFT Account Request Template
# This file shows how to request new AWS accounts through AFT
# Copy this template and modify for each new account request

module "staging_workload_account" {
  source = "./modules/aft-account-request"

  control_tower_parameters = {
    AccountEmail              = "staging-workload@tadeumendonca.io"
    AccountName               = "TadeumendoncaIO-Staging"
    ManagedOrganizationalUnit = "Staging"
    SSOUserEmail              = "admin@tadeumendonca.io"
    SSOUserFirstName          = "Staging"
    SSOUserLastName           = "Admin"
  }

  account_tags = {
    Environment = "staging"
    Owner       = "tadeumendonca"
    Project     = "aws-landing-zone"
    Workload    = "tadeumendonca-io"
  }

  change_management_parameters = {
    change_requested_by = "tadeumendonca"
    change_reason       = "New staging workload account for tadeumendonca.io"
  }

  custom_fields = {
    cost_center = "engineering"
    compliance  = "standard"
  }

  account_customizations_name = "staging-workload"
}

module "production_workload_account" {
  source = "./modules/aft-account-request"

  control_tower_parameters = {
    AccountEmail              = "production-workload@tadeumendonca.io"
    AccountName               = "TadeumendoncaIO-Production"
    ManagedOrganizationalUnit = "Production"
    SSOUserEmail              = "admin@tadeumendonca.io"
    SSOUserFirstName          = "Production"
    SSOUserLastName           = "Admin"
  }

  account_tags = {
    Environment = "production"
    Owner       = "tadeumendonca"
    Project     = "aws-landing-zone"
    Workload    = "tadeumendonca-io"
  }

  change_management_parameters = {
    change_requested_by = "tadeumendonca"
    change_reason       = "New production workload account for tadeumendonca.io"
  }

  custom_fields = {
    cost_center = "engineering"
    compliance  = "high"
  }

  account_customizations_name = "production-workload"
}