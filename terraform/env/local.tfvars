aws_region                    = "us-east-1"
aws_profile                   = "tadeumendonca-vpc"
customer_workload_name        = "tadeumendonca.io"
customer_workload_owner       = "tadeu.mendonca"
customer_workload_sponsor     = "tadeu.mendonca"
customer_workload_environment = "main"

# Workload environments to deploy (staging only for now)
workload_environments = ["staging"]

# DocumentDB configuration for each environment
documentdb_config = {
  staging = {
    engine_version                         = "4.0.0"
    master_username                        = "docdb"
    instance_count                         = 1
    instance_class                         = "db.t3.medium"
    backup_retention                       = 3
    preferred_backup_window                = "07:00-09:00"
    preferred_maintenance_window           = "sun:05:00-sun:06:00"
    deletion_protection                    = false
    skip_final_snapshot                    = true
    cloudwatch_logs                        = ["audit"]
    create_parameter_group                 = false
    db_cluster_parameter_group_name        = ""
    db_cluster_parameter_group_description = ""
    db_cluster_parameter_group_family      = ""
    db_cluster_parameter_group_parameters  = []
    cluster_tags                           = {}
  }
}