################################################################################
# Cluster
################################################################################

variable "cluster_identifier" {
  description = "The cluster identifier. If omitted, Terraform will assign a random, unique identifier"
  type        = string
  default     = null
}

variable "engine" {
  description = "The name of the database engine to be used for this DB cluster. Defaults to `docdb`. Valid values: `docdb`"
  type        = string
  default     = "docdb"
}

variable "engine_version" {
  description = "The database engine version. Updating this argument results in an outage"
  type        = string
  default     = "4.0.0"
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "docdb"
}

variable "master_password" {
  description = "Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file. If not provided, a random password will be generated"
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
  default     = true
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = number
  default     = 27017
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate with the Cluster"
  type        = list(string)
  default     = []
}

variable "db_subnet_group_name" {
  description = "A DB subnet group to associate with this DB instance"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
  default     = []
}

################################################################################
# Cluster Parameter Group
################################################################################

variable "create_db_cluster_parameter_group" {
  description = "Determines whether a cluster parameter group is created"
  type        = bool
  default     = false
}

variable "db_cluster_parameter_group_name" {
  description = "The name of the DB cluster parameter group"
  type        = string
  default     = null
}

variable "db_cluster_parameter_group_description" {
  description = "The description of the DB cluster parameter group"
  type        = string
  default     = null
}

variable "db_cluster_parameter_group_family" {
  description = "The DB cluster parameter group family"
  type        = string
  default     = "docdb4.0"
}

variable "db_cluster_parameter_group_parameters" {
  description = "A list of DB cluster parameters to apply"
  type = list(object({
    apply_method = string
    name         = string
    value        = string
  }))
  default = []
}

################################################################################
# Cluster Instance(s)
################################################################################

variable "instances" {
  description = "Map of cluster instances and any specific/overriding attributes to be created"
  type        = any
  default     = {}
}

variable "instance_class" {
  description = "The instance class to use. For details on CPU and memory, see Scaling for DocumentDB instances"
  type        = string
  default     = "db.t3.medium"
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  type        = bool
  default     = true
}

variable "ca_cert_identifier" {
  description = "The identifier of the CA certificate for the DB instance"
  type        = string
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "Copy all Cluster tags to snapshots"
  type        = bool
  default     = true
}

################################################################################
# Backup & Maintenance
################################################################################

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "The daily time range during which automated backups are created if automated backups are enabled using the BackupRetentionPeriod parameter. Time in UTC"
  type        = string
  default     = "07:00-09:00"
}

variable "preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur, in (UTC)"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB cluster is deleted"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "The name of your final DB snapshot when this DB cluster is deleted. If omitted, no final snapshot will be made"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "A value that indicates whether the DB cluster has deletion protection enabled"
  type        = bool
  default     = false
}

################################################################################
# Encryption
################################################################################

variable "storage_encrypted" {
  description = "Specifies whether the DB cluster is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. When specifying `kms_key_id`, `storage_encrypted` needs to be set to `true`"
  type        = string
  default     = null
}

################################################################################
# CloudWatch Logs
################################################################################

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to cloudwatch. The following log types are supported: `audit`, `profiler`"
  type        = list(string)
  default     = []
}

################################################################################
# Global Cluster
################################################################################

variable "global_cluster_identifier" {
  description = "The global cluster identifier specified on `aws_docdb_global_cluster`"
  type        = string
  default     = null
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "cluster_tags" {
  description = "Additional tags for the cluster"
  type        = map(string)
  default     = {}
}

variable "cluster_parameter_group_tags" {
  description = "Additional tags for the cluster parameter group"
  type        = map(string)
  default     = {}
}

variable "subnet_group_tags" {
  description = "Additional tags for the subnet group"
  type        = map(string)
  default     = {}
}