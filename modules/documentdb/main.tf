################################################################################
# Random Password
################################################################################

resource "random_password" "master_password" {
  count = var.manage_master_user_password && var.master_password == null ? 1 : 0

  length  = 16
  special = true
}

locals {
  master_password = var.manage_master_user_password ? (
    var.master_password != null ? var.master_password : random_password.master_password[0].result
  ) : var.master_password
}

################################################################################
# DB Subnet Group
################################################################################

resource "aws_docdb_subnet_group" "this" {
  count = var.db_subnet_group_name == null && length(var.subnet_ids) > 0 ? 1 : 0

  name       = var.cluster_identifier
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    var.subnet_group_tags,
    {
      Name = var.cluster_identifier
    }
  )
}

locals {
  db_subnet_group_name = var.db_subnet_group_name != null ? var.db_subnet_group_name : try(aws_docdb_subnet_group.this[0].name, null)
}

################################################################################
# Cluster Parameter Group
################################################################################

resource "aws_docdb_cluster_parameter_group" "this" {
  count = var.create_db_cluster_parameter_group ? 1 : 0

  name        = var.db_cluster_parameter_group_name
  family      = var.db_cluster_parameter_group_family
  description = var.db_cluster_parameter_group_description

  dynamic "parameter" {
    for_each = var.db_cluster_parameter_group_parameters

    content {
      apply_method = parameter.value.apply_method
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  tags = merge(
    var.tags,
    var.cluster_parameter_group_tags,
    {
      Name = var.db_cluster_parameter_group_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Cluster
################################################################################

resource "aws_docdb_cluster" "this" {
  cluster_identifier              = var.cluster_identifier
  engine                          = var.engine
  engine_version                  = var.engine_version
  master_username                 = var.master_username
  master_password                 = var.manage_master_user_password ? null : local.master_password
  manage_master_user_password     = var.manage_master_user_password
  port                            = var.port
  vpc_security_group_ids          = var.vpc_security_group_ids
  db_subnet_group_name            = local.db_subnet_group_name
  db_cluster_parameter_group_name = var.create_db_cluster_parameter_group ? aws_docdb_cluster_parameter_group.this[0].name : var.db_cluster_parameter_group_name

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.final_snapshot_identifier
  deletion_protection          = var.deletion_protection

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  global_cluster_identifier       = var.global_cluster_identifier

  tags = merge(
    var.tags,
    var.cluster_tags,
    {
      Name = var.cluster_identifier
    }
  )

  depends_on = [
    aws_docdb_cluster_parameter_group.this,
    aws_docdb_subnet_group.this
  ]
}

################################################################################
# Cluster Instance(s)
################################################################################

resource "aws_docdb_cluster_instance" "this" {
  for_each = var.instances

  identifier                   = try(each.value.identifier, "${var.cluster_identifier}-${each.key}")
  cluster_identifier           = aws_docdb_cluster.this.id
  instance_class               = try(each.value.instance_class, var.instance_class)
  engine                       = var.engine
  auto_minor_version_upgrade   = try(each.value.auto_minor_version_upgrade, var.auto_minor_version_upgrade)
  ca_cert_identifier           = try(each.value.ca_cert_identifier, var.ca_cert_identifier)
  preferred_maintenance_window = try(each.value.preferred_maintenance_window, var.preferred_maintenance_window)

  tags = merge(
    var.tags,
    try(each.value.tags, {}),
    {
      Name = try(each.value.identifier, "${var.cluster_identifier}-${each.key}")
    }
  )
}