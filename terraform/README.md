# Web Application Hosting Infrastructure

This Terraform configuration sets up the foundational infrastructure for hosting web applications on AWS.

## Architecture

- **VPC**: 10.0.0.0/16 with public/private subnets across 2 AZs
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (for ALB, NAT gateways)
- **Private Subnets**: 10.0.10.0/24, 10.0.20.0/24 (for EKS worker nodes)
- **Database Subnets**: 10.0.100.0/24, 10.0.200.0/24 (for RDS)
- **S3 Buckets**: Assets and backups with intelligent tiering
- **Security Groups**: EKS control plane, worker nodes, ALB, and RDS

## Modules Used

- `terraform-aws-modules/vpc/aws` - VPC and networking
- `terraform-aws-modules/s3-bucket/aws` - S3 buckets with best practices

## Deployment

This infrastructure is deployed via GitHub Actions using Terraform Cloud:

1. Push changes to the repository
2. GitHub Actions will run `terraform plan`
3. Review the plan in Terraform Cloud
4. Apply changes through Terraform Cloud workflow

## Environment Configuration

- **Main Environment**: Uses `terraform/env/main.tfvars`
- **Local Development**: Uses `terraform/env/local.tfvars` (with AWS profile)

## Security Features

- All S3 buckets block public access
- Security groups follow least-privilege principles
- Database subnets isolated from internet access
- Encryption at rest for S3 buckets
- VPC flow logs enabled (future enhancement)

## Cost Optimization

- S3 intelligent tiering enabled
- Lifecycle policies for backup retention
- Single NAT gateway per AZ (not single for all AZs)
- Appropriate instance sizing for startup workloads