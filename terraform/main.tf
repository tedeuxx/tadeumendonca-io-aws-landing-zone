############################
# MAIN INFRASTRUCTURE
############################

# VPC Module using official AWS community module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.customer_workload_name}-vpc"
  cidr = "10.0.0.0/16"

  azs              = slice(local.aws_availability_zones, 0, 2) # Use first 2 AZs
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.20.0/24"]
  database_subnets = ["10.0.100.0/24", "10.0.200.0/24"]

  # Enable NAT Gateway for private subnets
  enable_nat_gateway     = true
  enable_vpn_gateway     = false
  single_nat_gateway     = false # Use one NAT gateway per AZ for HA
  one_nat_gateway_per_az = true

  # Enable DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Create database subnet group
  create_database_subnet_group = true
  database_subnet_group_name   = "${local.customer_workload_name}-db-subnet-group"

  # Tags
  tags = {
    Name        = "${local.customer_workload_name}-vpc"
    Environment = var.customer_workload_environment
  }

  public_subnet_tags = {
    Type                     = "public"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    Type                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
  }

  database_subnet_tags = {
    Type = "database"
  }
}

# S3 Buckets for application assets and backups
module "assets_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${local.customer_workload_name}-assets-${random_id.bucket_suffix.hex}"

  # Versioning
  versioning = {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Name        = "${local.customer_workload_name}-assets"
    Environment = var.customer_workload_environment
    Purpose     = "application-assets"
  }
}

# Separate lifecycle configuration for assets bucket
resource "aws_s3_bucket_lifecycle_configuration" "assets_bucket_lifecycle" {
  bucket = module.assets_bucket.s3_bucket_id

  rule {
    id     = "intelligent_tiering"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Separate intelligent tiering configuration for assets bucket
resource "aws_s3_bucket_intelligent_tiering_configuration" "assets_bucket_tiering" {
  bucket = module.assets_bucket.s3_bucket_id
  name   = "EntireBucket"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

module "backups_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${local.customer_workload_name}-backups-${random_id.bucket_suffix.hex}"

  # Versioning
  versioning = {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Name        = "${local.customer_workload_name}-backups"
    Environment = var.customer_workload_environment
    Purpose     = "application-backups"
  }
}

# Separate lifecycle configuration for backups bucket
resource "aws_s3_bucket_lifecycle_configuration" "backups_bucket_lifecycle" {
  bucket = module.backups_bucket.s3_bucket_id

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2555 # 7 years retention
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Random ID for bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

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
    Purpose     = "application-load-balancer"
  }
}

# Security group for RDS PostgreSQL
resource "aws_security_group" "rds" {
  name_prefix = "${local.customer_workload_name}-rds-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for RDS PostgreSQL"

  # Allow PostgreSQL from EKS worker nodes only
  ingress {
    from_port                = 5432
    to_port                  = 5432
    protocol                 = "tcp"
    source_security_group_id = module.eks.node_security_group_id
    description              = "PostgreSQL from EKS worker nodes"
  }

  # No outbound rules needed for RDS

  tags = {
    Name        = "${local.customer_workload_name}-rds-sg"
    Environment = var.customer_workload_environment
    Purpose     = "rds-database"
  }
}