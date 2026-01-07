############################
# SECURITY GROUPS
############################

# Security group for Application Load Balancer
resource "aws_security_group" "alb" {
  name_prefix = "${local.customer_workload_name}-alb-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for Application Load Balancer"

  # Allow HTTP from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  # Allow HTTPS from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${local.customer_workload_name}-alb-sg"
    Environment = var.customer_workload_environment
    Owner       = var.customer_workload_owner
    Purpose     = "application-load-balancer"
    Tier        = "public"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security group for EKS Fargate pods
resource "aws_security_group" "eks_fargate" {
  name_prefix = "${local.customer_workload_name}-eks-fargate-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for EKS Fargate pods"

  # Allow traffic from ALB
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Traffic from ALB"
  }

  # Allow inter-pod communication within the same security group
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Inter-pod communication"
  }

  # Allow HTTPS outbound for pulling images and API calls
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  # Allow HTTP outbound for package downloads
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound"
  }

  # Allow DNS resolution
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS resolution"
  }

  # Allow DocumentDB access
  egress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = module.vpc.database_subnets_cidr_blocks
    description = "DocumentDB access"
  }

  tags = {
    Name        = "${local.customer_workload_name}-eks-fargate-sg"
    Environment = var.customer_workload_environment
    Owner       = var.customer_workload_owner
    Purpose     = "eks-fargate-pods"
    Tier        = "application"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security group for DocumentDB
resource "aws_security_group" "documentdb" {
  name_prefix = "${local.customer_workload_name}-documentdb-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for DocumentDB cluster"

  # Allow DocumentDB access from EKS Fargate pods only
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_fargate.id]
    description     = "DocumentDB from EKS Fargate"
  }

  # No outbound rules needed for DocumentDB

  tags = {
    Name        = "${local.customer_workload_name}-documentdb-sg"
    Environment = var.customer_workload_environment
    Owner       = var.customer_workload_owner
    Purpose     = "documentdb-database"
    Tier        = "data"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${local.customer_workload_name}-vpc-endpoints-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for VPC endpoints"

  # Allow HTTPS from private subnets
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
    description = "HTTPS from private subnets"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${local.customer_workload_name}-vpc-endpoints-sg"
    Environment = var.customer_workload_environment
    Owner       = var.customer_workload_owner
    Purpose     = "vpc-endpoints"
    Tier        = "infrastructure"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security group for EKS cluster control plane (managed by AWS but we can reference it)
resource "aws_security_group" "eks_cluster_additional" {
  name_prefix = "${local.customer_workload_name}-eks-cluster-additional-"
  vpc_id      = module.vpc.vpc_id
  description = "Additional security group for EKS cluster control plane"

  # Allow HTTPS from Fargate pods for API server access
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_fargate.id]
    description     = "HTTPS from Fargate pods"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${local.customer_workload_name}-eks-cluster-additional-sg"
    Environment = var.customer_workload_environment
    Owner       = var.customer_workload_owner
    Purpose     = "eks-cluster-additional"
    Tier        = "control-plane"
  }

  lifecycle {
    create_before_destroy = true
  }
}