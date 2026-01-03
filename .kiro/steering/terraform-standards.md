---
inclusion: fileMatch
fileMatchPattern: "*.tf"
---

# Terraform Standards

## Code Style
- Use snake_case for resource names
- Include description for all variables
- Use consistent indentation (2 spaces)
- Group related resources together

## Required Tags
All resources should include:
- Environment
- Project
- Owner
- CostCenter

## Security
- No hardcoded secrets
- Use data sources for sensitive values
- Enable encryption where available