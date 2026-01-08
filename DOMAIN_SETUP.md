# 🌐 Domain Setup Guide

This guide helps you configure your own domain when forking this AWS Landing Zone repository.

## 📋 Prerequisites

Before deploying this infrastructure, you need:

1. **Domain Ownership**: A registered domain name (e.g., `yourdomain.com`)
2. **AWS Account**: Access to AWS console with appropriate permissions
3. **Domain Registrar Access**: Ability to update nameservers at your registrar

## 🔧 Step-by-Step Configuration

### Step 1: Update Terraform Variables

Edit `terraform/env/main.tfvars` and update the domain configuration:

```hcl
# Replace with your actual domain
root_domain_name = "yourdomain.com"

# Optional: Customize application subdomains
applications = {
  webapp = {
    subdomain   = "app"        # Creates app.yourdomain.com
    description = "Main web application"
  }
  admin = {
    subdomain   = "admin"      # Creates admin.yourdomain.com  
    description = "Admin dashboard"
  }
  docs = {
    subdomain   = "docs"       # Creates docs.yourdomain.com
    description = "API documentation"
  }
}
```

### Step 2: Create Route53 Hosted Zone

1. **Go to AWS Route53 Console**:
   - Navigate to [Route53 Console](https://console.aws.amazon.com/route53/)
   - Click "Hosted zones" in the left sidebar

2. **Create Hosted Zone**:
   ```
   Domain name: yourdomain.com
   Type: Public hosted zone
   ```

3. **Note the Nameservers**:
   - After creation, note the 4 nameservers (e.g., `ns-123.awsdns-12.com`)
   - You'll need these for the next step

### Step 3: Update Domain Registrar

Update your domain registrar's nameservers to point to AWS Route53:

**Common Registrars:**
- **GoDaddy**: Domain Settings → Nameservers → Custom
- **Namecheap**: Domain List → Manage → Nameservers → Custom DNS
- **Google Domains**: DNS → Name servers → Custom name servers
- **Cloudflare**: DNS → Nameservers

**Example Nameservers** (yours will be different):
```
ns-123.awsdns-12.com
ns-456.awsdns-34.net
ns-789.awsdns-56.org
ns-012.awsdns-78.co.uk
```

⏰ **DNS Propagation**: Changes can take 24-48 hours to fully propagate.

### Step 4: Request ACM Certificate

1. **Go to Certificate Manager (us-east-1)**:
   - ⚠️ **Important**: Must be in `us-east-1` region for CloudFront
   - Navigate to [ACM Console](https://console.aws.amazon.com/acm/home?region=us-east-1)

2. **Request Certificate**:
   ```
   Domain names: *.yourdomain.com
   Validation method: DNS validation (recommended)
   Key algorithm: RSA 2048
   ```

3. **Complete DNS Validation**:
   - ACM will provide CNAME records to add to Route53
   - Add these records to your hosted zone
   - Wait for validation (usually 5-30 minutes)

### Step 5: Verify Configuration

Before deploying, verify your setup:

```bash
# Check DNS resolution
nslookup yourdomain.com

# Check nameservers
dig NS yourdomain.com

# Verify certificate (after validation)
# Check ACM console for "Issued" status
```

## 🎯 Expected Domain Pattern

After deployment, your applications will be available at:

### Production Environment
- **Main App**: `https://app.yourdomain.com`
- **Admin**: `https://admin.yourdomain.com`
- **Docs**: `https://docs.yourdomain.com`

### Staging Environment
- **Main App**: `https://app.staging.yourdomain.com`
- **Admin**: `https://admin.staging.yourdomain.com`
- **Docs**: `https://docs.staging.yourdomain.com`

## 🔍 Troubleshooting

### Common Issues

**1. Certificate Validation Fails**
```bash
# Check if CNAME records are correct
dig CNAME _abc123.yourdomain.com
```
- Ensure CNAME records are added to Route53
- Wait up to 30 minutes for validation

**2. DNS Not Resolving**
```bash
# Check nameserver propagation
dig NS yourdomain.com @8.8.8.8
```
- Verify nameservers at registrar match Route53
- Wait 24-48 hours for full propagation

**3. Terraform Plan Fails**
```
Error: No hosted zone found
```
- Ensure Route53 hosted zone exists
- Verify `root_domain_name` variable is correct
- Check AWS region and permissions

**4. CloudFront Distribution Fails**
```
Error: Certificate not found
```
- Ensure ACM certificate is in `us-east-1` region
- Verify certificate status is "Issued"
- Check wildcard pattern matches domain

### Validation Commands

```bash
# Test Route53 hosted zone
aws route53 list-hosted-zones-by-name --dns-name yourdomain.com

# Test ACM certificate (us-east-1)
aws acm list-certificates --region us-east-1 --certificate-statuses ISSUED

# Test Terraform configuration
terraform plan -var-file=env/main.tfvars -var-file=env/local.tfvars
```

## 📚 Additional Resources

- [AWS Route53 Documentation](https://docs.aws.amazon.com/route53/)
- [AWS Certificate Manager Documentation](https://docs.aws.amazon.com/acm/)
- [CloudFront Custom Domain Setup](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/CNAMEs.html)

## 🆘 Need Help?

If you encounter issues:

1. **Check AWS Documentation**: Links provided above
2. **Review Terraform Logs**: Run with `-var-file` flags for detailed output
3. **Open an Issue**: [GitHub Issues](https://github.com/tedeuxx/tadeumendonca-io-aws-landing-zone/issues)
4. **Contact**: [LinkedIn](https://www.linkedin.com/in/luiz-tadeu-mendonca-83a16530/)

---

*Remember: Domain setup is a one-time configuration. Once completed, the infrastructure will automatically manage DNS records and SSL certificates.*