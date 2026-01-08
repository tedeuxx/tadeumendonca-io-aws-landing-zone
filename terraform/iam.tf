############################
# IAM POLICIES FOR VPC FLOW LOGS
############################

# VPC Flow Logs IAM role using community module
module "vpc_flow_logs_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.44"

  trusted_role_services = ["vpc-flow-logs.amazonaws.com"]

  create_role = true
  role_name   = "${local.customer_workload_name}-vpc-flow-logs-role"

  custom_role_policy_arns = [module.vpc_flow_logs_policy.arn]

  tags = merge(local.common_tags, {
    Name    = "${local.customer_workload_name}-vpc-flow-logs-role"
    Purpose = "vpc-flow-logs"
  })
}

# VPC Flow Logs IAM policy using community module
module "vpc_flow_logs_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.44"

  name        = "${local.customer_workload_name}-vpc-flow-logs-policy"
  description = "IAM policy for VPC Flow Logs to write to S3"

  policy = data.aws_iam_policy_document.vpc_flow_logs_policy.json

  tags = merge(local.common_tags, {
    Name    = "${local.customer_workload_name}-vpc-flow-logs-policy"
    Purpose = "vpc-flow-logs"
  })
}