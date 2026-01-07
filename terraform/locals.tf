# Local variables
locals {
  aws_region             = data.aws_region.current.name
  aws_account_id         = data.aws_caller_identity.current.account_id
  aws_availability_zones = data.aws_availability_zones.azs.names
  customer_workload_name = var.customer_workload_name

  # ELB service account IDs by region for ALB access logs
  # Reference: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
  elb_service_account_id = {
    us-east-1      = "127311923021"
    us-east-2      = "033677994240"
    us-west-1      = "027434742980"
    us-west-2      = "797873946194"
    eu-west-1      = "156460612806"
    eu-central-1   = "054676820928"
    ap-southeast-1 = "114774131450"
    ap-northeast-1 = "582318560864"
  }

  # DocumentDB environment-specific configurations
  documentdb_config = {
    staging = {
      instance_count         = 1
      instance_class         = "db.t3.medium"
      backup_retention       = 3
      deletion_protection    = false
      skip_final_snapshot    = true
      cloudwatch_logs        = ["audit"]
      create_parameter_group = false
      cluster_tags           = {}
    }
    production = {
      instance_count         = 2
      instance_class         = "db.t3.medium"
      backup_retention       = 7
      deletion_protection    = true
      skip_final_snapshot    = false
      cloudwatch_logs        = ["audit", "profiler"]
      create_parameter_group = true
      cluster_tags = {
        Backup = "required"
      }
    }
  }
}
