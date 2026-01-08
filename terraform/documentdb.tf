############################
# DOCUMENTDB CLUSTERS
############################

# DocumentDB Clusters (for_each based on environments)
# Only create DocumentDB for environments that have configuration AND are in workload_environments
module "documentdb" {
  for_each = {
    for env in var.workload_environments :
    env => var.documentdb_config[env]
    if contains(keys(var.documentdb_config), env)
  }

  source = "../modules/documentdb"

  cluster_identifier = "${replace(local.customer_workload_name, ".", "-")}-${each.key}"
  engine_version     = each.value.engine_version
  master_username    = each.value.master_username

  # Network configuration
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [aws_security_group.documentdb.id]

  # Dynamic instance configuration based on environment
  instances = {
    for i in range(each.value.instance_count) :
    tostring(i + 1) => {
      identifier     = "${replace(local.customer_workload_name, ".", "-")}-${each.key}-${i + 1}"
      instance_class = each.value.instance_class
    }
  }

  # Backup and maintenance configuration
  backup_retention_period      = each.value.backup_retention
  preferred_backup_window      = each.value.preferred_backup_window
  preferred_maintenance_window = each.value.preferred_maintenance_window
  deletion_protection          = each.value.deletion_protection
  skip_final_snapshot          = each.value.skip_final_snapshot
  final_snapshot_identifier    = each.value.skip_final_snapshot ? null : "${replace(local.customer_workload_name, ".", "-")}-${each.key}-final-snapshot"

  # Security configuration
  storage_encrypted = true

  # Monitoring
  enabled_cloudwatch_logs_exports = each.value.cloudwatch_logs

  # Parameter group configuration
  create_db_cluster_parameter_group      = each.value.create_parameter_group
  db_cluster_parameter_group_name        = each.value.create_parameter_group ? "${replace(local.customer_workload_name, ".", "-")}-${each.key}-${each.value.db_cluster_parameter_group_name}" : null
  db_cluster_parameter_group_description = each.value.db_cluster_parameter_group_description
  db_cluster_parameter_group_family      = each.value.db_cluster_parameter_group_family
  db_cluster_parameter_group_parameters  = each.value.db_cluster_parameter_group_parameters

  tags = {
    Name        = "${local.customer_workload_name}-${each.key}-documentdb"
    Environment = each.key
    Owner       = var.customer_workload_owner
    Purpose     = "${each.key}-database"
    Terraform   = "true"
  }

  cluster_tags = each.value.cluster_tags
}