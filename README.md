# 🚀 tadeumendonca-io-aws-landing-zone

**Empowering digital products with AI-augmented, security-first cloud infrastructure**
*A long-term public project to build, learn, and share how to accelerate development using AWS services, generative AI tools, and startup-proven security practices.*

---

## 🌱 Purpose

As a cloud architect, I help businesses scale with cloud-native technologies. This project is my way of applying that same knowledge — outside working hours — to build a robust, secure, and cost-efficient foundation for future digital ventures.

It’s a long-term commitment to turn experience into ownership and prepare for the moment when building digital products becomes my main activity.

---

## 🧱 What You'll Find Here

This repository documents and implements a long-term, cloud-native architecture aligned with AWS best practices — designed to accelerate the creation of digital products using modern infrastructure, generative AI tools, and security by design. It includes:

* **Multi-account setup with AWS Control Tower**
* **Centralized authentication and fine-grained authorization**
* **Security-first infrastructure design**
* **PWA architecture for frontend delivery**
* **AI-augmented development with Amazon Q Developer**
* **End-to-end observability**
* **CI/CD with GitOps and security scanning**
* **Search and personalization**
* **Media streaming infrastructure**

---

## 📦 Prerequisites to Reuse This Project

### ✅ Local Setup

* [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) (`>= 1.5`)
* Git installed and access to clone this repository

### 🔧 Developer Setup

After cloning the repository, install Git hooks for automatic code formatting:

```bash
# Install Git hooks (run once after cloning)
./scripts/install-git-hooks.sh
```

**What this does:**
- Installs a pre-commit hook that automatically runs `terraform fmt`
- Ensures all Terraform files are properly formatted before commits
- Maintains consistent code style across all contributors

**Usage:**
- Hooks run automatically on `git commit`
- Skip hook if needed: `git commit --no-verify`
- Test hook manually: `.git/hooks/pre-commit`

---

### 🚀 Environment Promotion Strategy

This project uses a **single Terraform workspace** with **environment promotion** capabilities:

#### Automatic Staging Deployment
- **Trigger**: Push to `main` branch
- **Environment**: Staging workloads only
- **Command**: `terraform apply -var-file=env/main.tfvars -var='workload_environments=["staging"]'`

#### Manual Production Promotion
- **Trigger**: GitHub Actions `workflow_dispatch` 
- **Environment**: Production workloads (requires approval)
- **Options**:
  - `staging`: Deploy staging only
  - `production`: Deploy production only  
  - `staging+production`: Deploy both environments

#### Local Development
```bash
# Staging environment (local development)
terraform plan -var-file=env/main.tfvars -var-file=env/local.tfvars -var='workload_environments=["staging"]'

# Production environment (local testing)
terraform plan -var-file=env/main.tfvars -var-file=env/local.tfvars -var='workload_environments=["production"]'

# Both environments
terraform plan -var-file=env/main.tfvars -var-file=env/local.tfvars -var='workload_environments=["staging","production"]'
```

**Benefits:**
- **Shared foundation**: Network and base resources deployed once
- **Controlled promotion**: Production requires manual approval
- **Cost optimization**: Start with staging, add production when ready
- **Single state**: Simplified management with environment isolation at resource level

---

### ✅ AWS Account Prerequisites

| Requirement | Description | Configuration |
|-------------|-------------|---------------|
| **Route53 Hosted Zone** | Public hosted zone for your domain | Must be configured for `root_domain_name` variable |
| **ACM Certificate** | Wildcard SSL certificate | Must be `*.yourdomain.com` in **us-east-1** region |
| **Domain Ownership** | Verified domain ownership | Required for Route53 and ACM certificate validation |

#### 🔧 Domain Configuration Steps

If you fork this repository, you'll need to configure your own domain:

1. **Update Domain Variable**:
   ```hcl
   # In terraform/env/main.tfvars
   root_domain_name = "yourdomain.com"  # Replace with your domain
   ```

2. **Create Route53 Hosted Zone**:
   - Go to AWS Route53 console
   - Create public hosted zone for your domain
   - Update your domain registrar's nameservers

3. **Request ACM Certificate**:
   - Go to AWS Certificate Manager (us-east-1 region)
   - Request wildcard certificate: `*.yourdomain.com`
   - Validate via DNS (recommended) or email

4. **Update Application Subdomains** (optional):
   ```hcl
   # In terraform/env/main.tfvars
   applications = {
     webapp = {
       subdomain   = "app"        # Creates app.yourdomain.com
       description = "Main web application"
     }
   }
   ```

**Expected Domain Pattern**:
- **Production**: `app.yourdomain.com`
- **Staging**: `app.staging.yourdomain.com`

---

### ✅ GitHub Setup (Pro Required)

| Requirement                | Why It Matters                                                 |
| -------------------------- | -------------------------------------------------------------- |
| **GitHub Pro (or higher)** | Required for unlimited private repositories and GitHub Actions |
| **Actions Enabled**        | Enables CI/CD via `.github/workflows/terraform.yml`            |
| **Secrets Configured**     | Stores credentials and tokens securely                         |

---

### ✅ Terraform Cloud Structure

| Layer            | Suggested Name              | Purpose                                              |
| ---------------- | --------------------------- | ---------------------------------------------------- |
| **Organization** | `your-org-domain`           | Groups all workspaces and projects                   |
| **Project**      | `aws-landing-zone`          | AWS Organization and landing zone management         |
| **Workspace**    | `aws-landing-zone-main`     | AWS Control Tower, OUs, SCPs, accounts               |
| **Workspace**    | `aws-account-baseline-main` | AFT-based account-level customizations               |
| **Billing Plan** | `Standard`                  | Required for team API tokens, VCS integrations, RBAC |

> ℹ️ **Workspace Naming Tip**: You don't need to include `-main` in your workspace name unless you're managing multiple branches (e.g. `-dev`, `-hml`, `-prod`). By default, each workspace should be configured to track the `main` branch via **Settings > Version Control > Branch** in Terraform Cloud.

---

### 🔐 Required GitHub Repository Secrets

Set the following secrets in **GitHub > Settings > Secrets > Actions**:

| Secret Name             | Purpose                                                      |
| ----------------------- | ------------------------------------------------------------ |
| `AWS_ACCESS_KEY_ID`     | IAM access key for Terraform to authenticate to AWS          |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key (never commit this to code)                   |
| `AWS_DEFAULT_REGION`    | AWS region to use (e.g. `us-east-1`)                         |
| `TERRAFORM_CLOUD_TOKEN` | Terraform Cloud **Team API token** for secure authentication |

> ⚠️ Use least-privilege IAM credentials and avoid root user keys.

#### Example GitHub Actions Environment Block

```yaml
env:
  AWS_ACCESS_KEY_ID:         ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY:     ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  TERRAFORM_CLOUD_TOKEN:     ${{ secrets.TERRAFORM_CLOUD_TOKEN }}
  TF_IN_AUTOMATION:          true
  TF_CLOUD_ORGANIZATION:     your-org-domain
  TF_WORKSPACE:              aws-landing-zone-main
```

---

## 🗂️ Project Directory Structure

```plaintext
tadeumendonca-io-aws-landing-zone/
├── .github/
│   └── workflows/
│       └── terraform.yml
│
├── scripts/
│   ├── install-git-hooks.sh    # Setup Git hooks for developers
│   └── pre-commit              # Pre-commit hook for terraform fmt
│
├── terraform/
│   ├── env/
│   │   └── main.tfvars
│   ├── modules/
│   │   ├── control_tower/
│   │   ├── account_baseline/
│   │   ├── org_units/
│   │   ├── scp_policies/
│   │   └── (more to come)
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
│
├── CONTRIBUTING.md
├── LICENSE
├── README.md
```

---

## 📚 Community, Commitment & Collaboration

### 📘️ Feature Activity Log

| Date       | Feature/Action                                                                                                               |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------- |
| 2025-08-03 | ✅ **Amazon Q Developer Corporate Setup** — configured to guide and accelerate infrastructure development across all modules. |

---

### 🏷️ Suggested GitHub Topics

| Topic             | Purpose                                               |
| ----------------- | ----------------------------------------------------- |
| `your-org-domain` | Groups all repositories in your digital organization  |
| `aws`             | Indicates AWS-specific infrastructure and services    |
| `landing-zone`    | Identifies secure multi-account architecture projects |

---

### 📌 My Commitments

* ✅ Public, transparent, and version-controlled
* ✅ Incrementally updated in my free time
* ✅ Documented with lessons learned and architectural insights
* ✅ Open to issues, ideas, and contributions

> This isn’t just infrastructure — it’s a builder’s ritual in motion.

---

### 💡 Why Make This Public?

Because sharing:

* Accelerates learning
* Builds credibility
* Helps others on a similar path
* Creates space for meaningful collaboration

---

### ⚖️ Choosing Plans: Standard (TFC) and Pro (GitHub)

This project assumes the use of:

* **Terraform Cloud Standard Tier**
* **GitHub Pro (or higher)**

These plans are recommended to enable secure, automated, and scalable workflows.

#### Terraform Cloud — Standard Tier

| ✅ Pros                                          | ❌ Cons                                |
| ----------------------------------------------- | ------------------------------------- |
| Enables **Team API Tokens** (secure automation) | Paid tier required (after free trial) |
| Supports **Run Triggers** across workspaces     |                                       |
| Enables **RBAC** and team collaboration         |                                       |
| Required for GitHub-integrated pipelines        |                                       |

**Limitations on Free Tier:**

* No support for Team API Tokens (must use user tokens tied to individuals)
* No RBAC, run triggers, or advanced automation

---

#### GitHub — Pro Plan

| ✅ Pros                                         | ❌ Cons             |
| ---------------------------------------------- | ------------------ |
| Unlimited **private repositories**             | Small monthly cost |
| Full **GitHub Actions minutes** for automation |                    |
| Ideal for personal or pre-commercial projects  |                    |

**Limitations on Free Tier:**

* Limited or no GitHub Actions for private repos
* All workflows must be public for automation to work
* No control over visibility or team-level permissions

---

### 🛠️ Adapting to Free Tiers (for experiments only)

You **can adapt** this solution for experimentation with free tiers by:

* Making the repository public
* Using **personal API tokens**
* Avoiding sensitive configurations in GitHub Actions
* Running `terraform apply` locally instead of CI/CD

> ⚠️ Warning: Free tier adaptations sacrifice security, scalability, and collaboration.

---

## 📬 Connect With Me

Follow the progress, star the repo, open issues, or drop me a message on [LinkedIn](https://www.linkedin.com/in/luiz-tadeu-mendonca-83a16530/). Let’s build better — together.

---

*"Think big, start small."*
