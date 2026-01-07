############################
# DOCUMENTDB CLUSTERS
############################

# Production DocumentDB Cluster (Multi-AZ)
module "documentdb_production" {
  source = "../modules/documentdb"

  cluster_identifier = "${replace(local.customer_workload_name, ".", "-")}-production"
  engine_version     = "4.0.0"
  master_username    = "docdb"

  # Network configuration
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [aws_security_group.documentdb.id]

  # Multi-AZ deployment with 2 instances for high availability
  instances = {
    1 = {
      identifier     = "${replace(local.customer_workload_name, ".", "-")}-production-1"
      instance_class = "db.t3.medium"
    }
    2 = {
      identifier     = "${replace(local.customer_workload_name, ".", "-")}-production-2"
      instance_class = "db.t3.medium"
    }
  }

  # Backup and maintenance configuration
  backup_retention_period      = 7
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"
  deletion_protection          = true
  skip_final_snapshot          = false
  final_snapshot_identifier    = "${replace(local.customer_workload_name, ".", "-")}-production-final-snapshot"

  # Security configuration
  storage_encrypted = true

  # Monitoring
  enabled_cloudwatch_logs_exports = ["audit", "profiler"]

  # Parameter group for production optimizations
  create_db_cluster_parameter_group      = true
  db_cluster_parameter_group_name        = "${replace(local.customer_workload_name, ".", "-")}-production-params"
  db_cluster_parameter_group_description = "DocumentDB cluster parameter group for production"
  db_cluster_parameter_group_family      = "docdb4.0"
  db_cluster_parameter_group_parameters = [
    {
      apply_method = "immediate"
      name         = "tls"
      value        = "enabled"
    }
  ]

  tags = {
    Name        = "${local.customer_workload_name}-production-documentdb"
    Environment = "production"
    Owner       = var.customer_workload_owner
    Purpose     = "production-database"
    Terraform   = "true"
  }

  cluster_tags = {
    Backup = "required"
  }
}

# Staging DocumentDB Cluster (Single-AZ for cost optimization)
module "documentdb_staging" {
  source = "../modules/documentdb"

  cluster_identifier = "${replace(local.customer_workload_name, ".", "-")}-staging"
  engine_version     = "4.0.0"
  master_username    = "docdb"

  # Network configuration
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [aws_security_group.documentdb.id]

  # Single instance for cost optimization
  instances = {
    1 = {
      identifier     = "${replace(local.customer_workload_name, ".", "-")}-staging-1"
      instance_class = "db.t3.medium"
    }
  }

  # Reduced backup retention for staging
  backup_retention_period      = 3
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"
  deletion_protection          = false
  skip_final_snapshot          = true

  # Security configuration
  storage_encrypted = true

  # Basic monitoring for staging
  enabled_cloudwatch_logs_exports = ["audit"]

  tags = {
    Name        = "${local.customer_workload_name}-staging-documentdb"
    Environment = "staging"
    Owner       = var.customer_workload_owner
    Purpose     = "staging-database"
    Terraform   = "true"
  }
}