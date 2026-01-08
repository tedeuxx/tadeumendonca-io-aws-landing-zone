# Local variables
locals {
  aws_region             = data.aws_region.current.id
  aws_account_id         = data.aws_caller_identity.current.account_id
  aws_availability_zones = data.aws_availability_zones.azs.names
  customer_workload_name = var.customer_workload_name

  # Common tags applied to all resources
  common_tags = {
    Terraform                     = "true"
    customer_workload_name        = var.customer_workload_name
    customer_workload_owner       = var.customer_workload_owner
    customer_workload_sponsor     = var.customer_workload_sponsor
    customer_workload_environment = var.customer_workload_environment
  }

  # Application-environment combinations for frontend infrastructure
  app_env_combinations = {
    for combo in setproduct(keys(var.applications), var.workload_environments) :
    "${combo[0]}-${combo[1]}" => {
      app_name    = combo[0]
      environment = combo[1]
      subdomain   = var.applications[combo[0]].subdomain
      description = var.applications[combo[0]].description
      # FQDN pattern: subdomain.environment.domain for staging, subdomain.domain for production
      fqdn = combo[1] == "production" ? "${var.applications[combo[0]].subdomain}.tadeumendonca.io" : "${var.applications[combo[0]].subdomain}.${combo[1]}.tadeumendonca.io"
    }
  }

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
}
