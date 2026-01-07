############################
# DOCUMENTDB CLUSTERS
############################

# DocumentDB Clusters (for_each based on environments)
module "documentdb" {
  for_each = toset(var.workload_environments)

  source = "../modules/documentdb"

  cluster_identifier = "${replace(local.customer_workload_name, ".", "-")}-${each.key}"
  engine_version     = "4.0.0"
  master_username    = "docdb"

  # Network configuration
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [aws_security_group.documentdb.id]

  # Dynamic instance configuration based on environment
  instances = {
    for i in range(local.documentdb_config[each.key].instance_count) :
    tostring(i + 1) => {
      identifier     = "${replace(local.customer_workload_name, ".", "-")}-${each.key}-${i + 1}"
      instance_class = local.documentdb_config[each.key].instance_class
    }
  }

  # Backup and maintenance configuration
  backup_retention_period      = local.documentdb_config[each.key].backup_retention
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"
  deletion_protection          = local.documentdb_config[each.key].deletion_protection
  skip_final_snapshot          = local.documentdb_config[each.key].skip_final_snapshot
  final_snapshot_identifier    = local.documentdb_config[each.key].skip_final_snapshot ? null : "${replace(local.customer_workload_name, ".", "-")}-${each.key}-final-snapshot"

  # Security configuration
  storage_encrypted = true

  # Monitoring
  enabled_cloudwatch_logs_exports = local.documentdb_config[each.key].cloudwatch_logs

  # Parameter group (only for production)
  create_db_cluster_parameter_group      = local.documentdb_config[each.key].create_parameter_group
  db_cluster_parameter_group_name        = local.documentdb_config[each.key].create_parameter_group ? "${replace(local.customer_workload_name, ".", "-")}-${each.key}-params" : null
  db_cluster_parameter_group_description = local.documentdb_config[each.key].create_parameter_group ? "DocumentDB cluster parameter group for ${each.key}" : null
  db_cluster_parameter_group_family      = local.documentdb_config[each.key].create_parameter_group ? "docdb4.0" : null
  db_cluster_parameter_group_parameters = local.documentdb_config[each.key].create_parameter_group ? [
    {
      apply_method = "immediate"
      name         = "tls"
      value        = "enabled"
    }
  ] : []

  tags = {
    Name        = "${local.customer_workload_name}-${each.key}-documentdb"
    Environment = each.key
    Owner       = var.customer_workload_owner
    Purpose     = "${each.key}-database"
    Terraform   = "true"
  }

  cluster_tags = local.documentdb_config[each.key].cluster_tags
}