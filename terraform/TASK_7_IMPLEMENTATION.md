# Task 7 Implementation: EKS Clusters + API Gateway REST API

## 🎯 Implementation Summary

This implementation creates separate EKS clusters per environment (staging/production) with API Gateway REST API integration using the latest AWS features.

## 🏗️ Architecture

```
Internet → API Gateway REST API → VPC Link → ALB (Host-based) → EKS Fargate
         (api-staging/api.tadeumendonca.io)     ↓
                                          Host-based routing:
                                          • api-staging.tadeumendonca.io → staging namespace
                                          • api.tadeumendonca.io → production namespace
```

## 📁 Files Created/Modified

### New Files:
- `terraform/eks.tf` - EKS clusters with Fargate profiles
- `terraform/eks-addons.tf` - AWS Load Balancer Controller, EBS CSI, etc.
- `terraform/api-gateway.tf` - REST APIs with custom domains
- `terraform/vpc-link.tf` - VPC Links for direct ALB integration + Kubernetes resources
- `terraform/waf-api.tf` - WAF protection for API Gateway

### Modified Files:
- `terraform/init.tf` - Added Kubernetes and Helm provider requirements
- `terraform/provider.tf` - Added Kubernetes and Helm provider configurations
- `terraform/variables.tf` - Added EKS, API Gateway, and WAF variables
- `terraform/locals.tf` - Added API domain names and EKS cluster names
- `terraform/outputs.tf` - Added comprehensive EKS and API Gateway outputs
- `terraform/route53.tf` - Added API domain DNS records
- `terraform/env/main.tfvars` - Added EKS and API Gateway configurations

## 🔧 Key Features

### EKS Clusters (per environment):
- **Fargate-only** data plane (serverless)
- **Private cluster endpoints** (no public access)
- **KMS encryption** for secrets
- **CloudWatch logging** enabled
- **Namespace isolation** between environments

### Fargate Profiles:
- `kube-system` - Core Kubernetes components
- `application` - Application workloads per environment
- `aws-observability` - Fluent Bit logging

### EKS Add-ons:
- **AWS Load Balancer Controller** - Creates internal ALBs
- **EBS CSI Driver** - Persistent storage
- **AWS Fluent Bit** - CloudWatch logging
- **Metrics Server** - HPA support
- **VPA** - Vertical Pod Autoscaler

### API Gateway REST API (per environment):
- **Custom domains**: `api-staging.tadeumendonca.io`, `api.tadeumendonca.io`
- **Direct ALB integration** (new AWS feature - Nov 2025)
- **CORS support** for frontend integration
- **CloudWatch logging** and X-Ray tracing
- **SSL termination** with ACM certificates

### WAF Protection:
- **AWS Managed Rules** (Common Rule Set, Known Bad Inputs)
- **Rate limiting** (1000 requests per 5 minutes per IP)
- **Geo-blocking** (China, Russia, North Korea, Iran)
- **SQL injection** and XSS protection
- **CloudWatch logging** for security events

### Kubernetes Resources:
- **Namespaces** per environment with pod security standards
- **Network policies** for namespace isolation
- **RBAC** configuration for service accounts
- **Ingress resources** to create internal ALBs
- **Placeholder services** for health checks

## 🌐 API Endpoints

- **Staging**: `https://api-staging.tadeumendonca.io`
- **Production**: `https://api.tadeumendonca.io`

## 💰 Estimated Monthly Costs

| Component | Staging | Production | Total |
|-----------|---------|------------|-------|
| EKS Control Plane | $72 | $72 | $144 |
| Fargate (estimated) | $80 | $150 | $230 |
| ALB | $16 | $16 | $32 |
| API Gateway | $10 | $20 | $30 |
| WAF | $5 | $5 | $10 |
| **TOTAL** | **$183** | **$263** | **$446/month** |

## 🚀 Key Benefits

1. **Latest AWS Features**: Direct API Gateway → ALB integration (no NLB needed)
2. **Complete Isolation**: Separate clusters per environment
3. **Serverless Compute**: Fargate-only (no EC2 management)
4. **Production Security**: Private clusters, WAF protection, namespace isolation
5. **Operational Excellence**: CloudWatch logging, monitoring, health checks
6. **Cost Optimized**: No unnecessary components, intelligent scaling

## ✅ Validation Steps

1. **EKS Clusters**: `kubectl get nodes` (should show Fargate nodes)
2. **Fargate Profiles**: `kubectl get pods -A` (pods running on Fargate)
3. **ALB Creation**: Check AWS Console for internal ALBs
4. **API Gateway**: Test custom domain endpoints
5. **WAF Protection**: Verify blocked requests in CloudWatch
6. **DNS Resolution**: `nslookup api-staging.tadeumendonca.io`

## 🔄 Next Steps (Future Tasks)

- **Task 8**: Add Istio service mesh
- **Task 9**: Deploy ArgoCD for GitOps
- **Task 10**: Add observability stack (Prometheus, Grafana, Kiali)

## 📋 Deployment Commands

```bash
# Initialize and plan
terraform init
terraform plan -var-file=./env/main.tfvars -var='workload_environments=["staging"]'

# Deploy staging first
terraform apply -var-file=./env/main.tfvars -var='workload_environments=["staging"]'

# Deploy both environments
terraform apply -var-file=./env/main.tfvars -var='workload_environments=["staging","production"]'
```

## 🔧 Post-Deployment Configuration

After deployment, you'll need to:

1. **Configure kubectl**: `aws eks update-kubeconfig --region us-east-1 --name tadeumendonca-io-staging`
2. **Deploy applications**: Replace placeholder services with actual applications
3. **Update DNS**: Verify Route53 records are resolving correctly
4. **Test API endpoints**: Verify health checks and API responses
5. **Monitor logs**: Check CloudWatch for EKS, API Gateway, and WAF logs

This implementation provides a production-ready foundation for containerized applications with modern AWS services and security best practices.