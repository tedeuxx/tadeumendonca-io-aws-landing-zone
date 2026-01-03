# Project Context

This is a Terraform infrastructure project using Terraform Cloud for state management.

## Key Information
- Infrastructure as Code using Terraform
- Environment-specific configurations in terraform/env/
- Backend: Terraform Cloud (remote state management)
- Follow Terraform best practices for naming and structure

## Build/Deploy Process
- Run `terraform plan` to preview changes
- Run `terraform apply` to deploy infrastructure
- State managed remotely via Terraform Cloud
- Use appropriate workspace for environment targeting

## Standards
- Use consistent naming conventions for resources
- Include proper tags on all resources
- Document all variables and outputs