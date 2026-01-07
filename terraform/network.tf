############################
# NETWORK INFRASTRUCTURE
############################

# VPC Module using official AWS community module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.customer_workload_name}-vpc"
  cidr = "10.0.0.0/16"

  # Use first 2 availability zones in the region
  azs = slice(local.aws_availability_zones, 0, 2)

  # Subnet configuration as per design
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]     # For ALB, WAF, NAT Gateway
  private_subnets  = ["10.0.10.0/24", "10.0.20.0/24"]   # For EKS Fargate pods
  database_subnets = ["10.0.100.0/24", "10.0.200.0/24"] # For DocumentDB

  # NAT Gateway configuration (single NAT for cost optimization)
  enable_nat_gateway     = true
  enable_vpn_gateway     = false
  single_nat_gateway     = true # Cost optimization: single NAT gateway
  one_nat_gateway_per_az = false

  # DNS configuration
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Database subnet group
  create_database_subnet_group = true
  database_subnet_group_name   = "${local.customer_workload_name}-db"

  # VPC Flow Logs for security monitoring
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_iam_role             = true
  create_flow_log_cloudwatch_log_group            = true
  flow_log_cloudwatch_log_group_retention_in_days = 30

  # Tags for the VPC
  tags = {
    Name        = "${local.customer_workload_name}-vpc"
    Environment = var.customer_workload_environment
    Owner       = var.customer_workload_owner
    Project     = "aws-landing-zone"
    Terraform   = "true"
  }

  # Public subnet tags (for ALB and internet-facing resources)
  public_subnet_tags = {
    Type                     = "public"
    "kubernetes.io/role/elb" = "1" # For AWS Load Balancer Controller
    Tier                     = "public"
  }

  # Private subnet tags (for EKS Fargate pods)
  private_subnet_tags = {
    Type                              = "private"
    "kubernetes.io/role/internal-elb" = "1" # For internal load balancers
    Tier                              = "application"
  }

  # Database subnet tags
  database_subnet_tags = {
    Type = "database"
    Tier = "data"
  }
}

# VPC Endpoints using terraform-aws-modules/vpc/aws endpoints feature
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
      tags = {
        Name        = "${local.customer_workload_name}-s3-endpoint"
        Environment = var.customer_workload_environment
        Owner       = var.customer_workload_owner
        Service     = "s3"
      }
    }

    ecr_dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      private_dns_enabled = true
      tags = {
        Name        = "${local.customer_workload_name}-ecr-dkr-endpoint"
        Environment = var.customer_workload_environment
        Owner       = var.customer_workload_owner
        Service     = "ecr-dkr"
      }
    }

    ecr_api = {
      service             = "ecr.api"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      private_dns_enabled = true
      tags = {
        Name        = "${local.customer_workload_name}-ecr-api-endpoint"
        Environment = var.customer_workload_environment
        Owner       = var.customer_workload_owner
        Service     = "ecr-api"
      }
    }

    logs = {
      service             = "logs"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      private_dns_enabled = true
      tags = {
        Name        = "${local.customer_workload_name}-logs-endpoint"
        Environment = var.customer_workload_environment
        Owner       = var.customer_workload_owner
        Service     = "cloudwatch-logs"
      }
    }
  }

  tags = {
    Environment = var.customer_workload_environment
    Owner       = var.customer_workload_owner
    Project     = "aws-landing-zone"
    Terraform   = "true"
  }
}