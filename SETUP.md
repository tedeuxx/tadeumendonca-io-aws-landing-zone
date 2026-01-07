# AWS Landing Zone - Setup Guide

This guide provides step-by-step instructions for setting up the CI/CD pipeline and local development environment for the Tadeumendonca.io AWS Landing Zone project.

## Overview

This project uses:
- **Terraform Cloud** for remote state management and execution
- **GitHub Actions** for automated CI/CD pipeline
- **AWS CLI** for local development and testing
- **Terraform** for infrastructure as code

## Prerequisites

- AWS Account with appropriate permissions
- GitHub account
- Terraform Cloud account (free tier sufficient)
- Local development machine (macOS/Linux/Windows)

## Step 1: Terraform Cloud Setup

### 1.1 Create Terraform Cloud Account
1. Visit [https://app.terraform.io/signup/account](https://app.terraform.io/signup/account)
2. Create account or sign in with existing account

### 1.2 Create Organization
1. In Terraform Cloud UI, click "Create Organization"
2. Enter organization name (e.g., "your-company-io")
3. Choose plan (Free tier sufficient for getting started)

### 1.3 Create Workspace
1. In your organization, click "New Workspace"
2. Choose "CLI-driven workflow"
3. Name: "aws-landing-zone-main"
4. Description: "AWS Landing Zone Infrastructure"

### 1.4 Configure Workspace Settings
1. Go to "Settings" > "General"
2. Set Terraform Version: "1.12.1" (or latest)
3. Set Execution Mode: "Remote"
4. Auto Apply: "Disabled" (for safety)

### 1.5 Set Environment Variables
In workspace "Variables" tab, add **Environment Variables**:
```
AWS_ACCESS_KEY_ID = your_aws_access_key (mark as sensitive)
AWS_SECRET_ACCESS_KEY = your_aws_secret_key (mark as sensitive)
```

Add **Terraform Variables**:
```
aws_region = "us-east-1"
customer_workload_name = "your-project-name"
customer_workload_owner = "your-email@domain.com"
customer_workload_sponsor = "sponsor-email@domain.com"
customer_workload_environment = "main"
```

### 1.6 Generate API Token
1. Click your avatar > "User Settings"
2. Go to "Tokens"
3. Click "Create an API token"
4. Name: "GitHub Actions"
5. Copy token (save securely - shown only once)

## Step 2: GitHub Repository Setup

### 2.1 Fork or Create Repository

**Option A: Fork this repository**
1. Click "Fork" on GitHub
2. Choose your account/organization

**Option B: Create new repository from template**
1. Click "Use this template"
2. Create new repository

**Option C: Clone and push to new repo**
```bash
git clone https://github.com/tadeumendonca/tadeumendonca-io-aws-landing-zone.git
cd tadeumendonca-io-aws-landing-zone
git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git push -u origin main
```

### 2.2 Configure Repository Secrets
1. Go to "Settings" > "Secrets and variables" > "Actions"
2. Click "New repository secret"
3. Add these secrets:

```
AWS_ACCESS_KEY_ID
Value: Your AWS access key ID

AWS_SECRET_ACCESS_KEY  
Value: Your AWS secret access key

TERRAFORM_CLOUD_TOKEN
Value: API token from Terraform Cloud (from Step 1.6)
```

### 2.3 Enable GitHub Actions
1. Go to "Actions" tab in repository
2. Click "I understand my workflows, go ahead and enable them"
3. Verify workflow file exists: `.github/workflows/terraform.yml`

### 2.4 Configure Branch Protection (Recommended)
1. Go to repository "Settings" > "Branches"
2. Click "Add rule"
3. Branch name pattern: "main"
4. Enable:
   - Require a pull request before merging
   - Require status checks to pass before merging
   - Require branches to be up to date before merging
   - Include administrators

## Step 3: Local Development Environment Setup

### 3.1 Install Required Tools

**macOS (using Homebrew):**
```bash
# Install Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify version (should be 1.12.1+)
terraform version

# Install AWS CLI
brew install awscli

# Verify installation
aws --version

# Install kubectl (for EKS management)
brew install kubectl

# Install jq (for JSON processing)
brew install jq
```

**Linux (Ubuntu/Debian):**
```bash
# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install AWS CLI
sudo apt install awscli

# Install kubectl
sudo apt install kubectl

# Install jq
sudo apt install jq
```

### 3.2 Configure AWS CLI
```bash
# Configure AWS credentials
aws configure --profile your-profile-name
# AWS Access Key ID: [your-access-key]
# AWS Secret Access Key: [your-secret-key]
# Default region name: us-east-1
# Default output format: json

# Test AWS connection
aws sts get-caller-identity --profile your-profile-name
```

### 3.3 Configure Terraform Cloud Credentials
```bash
# Create Terraform credentials file
mkdir -p ~/.terraform.d

# Create credentials file
cat > ~/.terraform.d/credentials.tfrc.json << EOF
{
  "credentials": {
    "app.terraform.io": {
      "token": "YOUR_TERRAFORM_CLOUD_TOKEN"
    }
  }
}
EOF

# Secure the file
chmod 600 ~/.terraform.d/credentials.tfrc.json
```

### 3.4 Clone and Configure Repository
```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME

# Update Terraform configuration with your values
# Edit terraform/init.tf
vim terraform/init.tf

# Update organization and workspace names:
# organization = "your-organization-name"
# name = "your-workspace-name"
```

### 3.5 Create Local Environment File
```bash
# Create local development variables
cat > terraform/env/local.tfvars << EOF
aws_region                    = "us-east-1"
aws_profile                   = "your-profile-name"
customer_workload_name        = "your-project-name"
customer_workload_owner       = "your-email@domain.com"
customer_workload_sponsor     = "sponsor-email@domain.com"
customer_workload_environment = "main"
EOF
```

### 3.6 Test Local Setup
```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Test plan (should connect to Terraform Cloud)
terraform plan -var-file=./env/local.tfvars

# If successful, you should see:
# "No changes. Your infrastructure matches the configuration."
# or planned changes if this is first run
```

## Step 4: Verify CI/CD Pipeline

### 4.1 Test GitHub Actions Workflow
```bash
# Make a small change to trigger workflow
echo "# Test change" >> README.md
git add README.md
git commit -m "test: trigger CI/CD pipeline"
git push origin main

# Check workflow execution:
# 1. Go to GitHub repository
# 2. Click "Actions" tab
# 3. Verify workflow runs successfully
# 4. Check that Terraform plan executes without errors
```

### 4.2 Test Manual Workflow Dispatch
1. In GitHub repository, go to "Actions" tab
2. Click "tadeumendonca-io-aws-landing-zone" workflow
3. Click "Run workflow"
4. Select "apply" or "destroy"
5. Click "Run workflow"
6. Monitor execution logs

## Step 5: Domain and DNS Setup (Optional)

### 5.1 Configure Route 53 Hosted Zone
```bash
# If you have a domain, create hosted zone in AWS
aws route53 create-hosted-zone \
  --name your-domain.com \
  --caller-reference $(date +%s) \
  --profile your-profile-name

# Note the Name Servers from output
# Update your domain registrar with these name servers
```

### 5.2 Verify DNS Resolution
```bash
# Test DNS resolution (may take 24-48 hours)
nslookup your-domain.com
dig your-domain.com NS
```

## Step 6: Cost Monitoring Setup

### 6.1 Configure AWS Billing Alerts
1. In AWS Console, go to Billing & Cost Management
2. Click "Budgets"
3. Create budget for $600/month (Phase 1 + buffer)
4. Set alerts at 50%, 80%, 100% of budget

### 6.2 Enable Cost Allocation Tags
1. In AWS Console, go to Billing & Cost Management
2. Click "Cost Allocation Tags"
3. Activate tags: Environment, Owner, Project

## Troubleshooting

### Terraform Cloud Connection Issues
```bash
# Error: "No valid credential sources found"
# Solution: Check ~/.terraform.d/credentials.tfrc.json

# Error: "Workspace not found"
# Solution: Verify organization and workspace names in terraform/init.tf

# Error: "Access denied"
# Solution: Check AWS credentials in Terraform Cloud workspace variables
```

### GitHub Actions Issues
```bash
# Error: "Terraform Cloud token invalid"
# Solution: Regenerate token in Terraform Cloud and update GitHub secret

# Error: "AWS credentials not found"
# Solution: Verify AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY secrets

# Error: "Terraform version mismatch"
# Solution: Update terraform version in .github/workflows/terraform.yml
```

### Local Development Issues
```bash
# Error: "Profile not found"
# Solution: Run 'aws configure --profile your-profile-name'

# Error: "Permission denied"
# Solution: Check IAM permissions for your AWS user/role

# Error: "Backend initialization failed"
# Solution: Verify Terraform Cloud credentials and workspace access
```

## Setup Verification Checklist

Before using the infrastructure:
- [ ] Terraform Cloud organization and workspace created
- [ ] GitHub repository forked/created with Actions enabled
- [ ] All required secrets configured in GitHub
- [ ] AWS CLI configured with appropriate profile
- [ ] Terraform Cloud credentials configured locally
- [ ] Local terraform init and plan successful
- [ ] GitHub Actions workflow tested and working
- [ ] Route 53 hosted zone configured (if using custom domain)
- [ ] AWS billing alerts configured
- [ ] Team access configured (if applicable)

## Next Steps

Once setup is complete, you can:
1. Review the [Architecture Documentation](docs/ARCHITECTURE.md)
2. Understand the [Cost Analysis](COST_ANALYSIS.md)
3. Follow the [Implementation Tasks](.kiro/specs/tadeumendonca-io-aws-landing-zone/tasks.md)
4. Deploy your first infrastructure changes

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review GitHub Issues in this repository
3. Consult Terraform Cloud documentation
4. Check AWS documentation for service-specific issues