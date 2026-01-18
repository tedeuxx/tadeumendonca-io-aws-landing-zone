# Amazon EKS Clusters with Fargate-only data plane
# Separate cluster per environment for complete isolation

############################
# EKS CLUSTERS
############################

# EKS cluster per environment using terraform-aws-modules/eks
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  for_each = toset(var.workload_environments)

  # Cluster configuration
  name               = "${replace(local.customer_workload_name, ".", "-")}-${each.value}"
  kubernetes_version = var.eks_cluster_version

  # VPC configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cluster endpoint configuration - private only for security
  endpoint_private_access = true
  endpoint_public_access  = false

  # Cluster logging
  enabled_log_types = var.enable_eks_cluster_logging ? var.eks_cluster_log_types : []

  # Fargate profiles for serverless compute
  fargate_profiles = {
    # System namespace for core Kubernetes components
    kube_system = {
      name = "${each.value}-kube-system"
      selectors = [
        {
          namespace = "kube-system"
        }
      ]
      subnet_ids = module.vpc.private_subnets
    }

    # Application namespace for workloads
    application = {
      name = "${each.value}-application"
      selectors = [
        {
          namespace = each.value
        }
      ]
      subnet_ids = module.vpc.private_subnets
    }
  }

  # EKS managed add-ons
  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  tags = merge(local.common_tags, {
    Name        = "${local.customer_workload_name}-${each.value}-eks"
    Environment = each.value
    Purpose     = "eks-fargate-cluster"
  })
}

############################
# KUBERNETES NAMESPACES
############################

# Create application namespaces for each environment
resource "kubernetes_namespace" "application" {
  for_each = toset(var.workload_environments)

  metadata {
    name = each.value
    labels = {
      name = each.value
    }
  }

  depends_on = [module.eks]
}

############################
# CLOUDWATCH LOG GROUPS
############################

# CloudWatch log group for Fargate container logs
resource "aws_cloudwatch_log_group" "fargate" {
  for_each = toset(var.workload_environments)

  name              = "/aws/eks/${module.eks[each.value].cluster_name}/fargate"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name        = "${local.customer_workload_name}-${each.value}-fargate-logs"
    Environment = each.value
    Purpose     = "eks-fargate-container-logs"
  })
}