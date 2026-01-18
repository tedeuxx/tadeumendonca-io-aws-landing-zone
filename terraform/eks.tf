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

  cluster_name    = "${replace(local.customer_workload_name, ".", "-")}-${each.value}"
  cluster_version = "1.30"

  # Cluster endpoint configuration - private only for security
  cluster_endpoint_config = {
    private_access = true
    public_access  = false
  }

  # VPC configuration
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # Cluster logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Cluster encryption
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks[each.value].arn
    resources        = ["secrets"]
  }

  # Fargate profiles for serverless compute
  fargate_profiles = {
    # System namespace for core Kubernetes components
    kube_system = {
      name = "${each.value}-kube-system"
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            "app.kubernetes.io/name" = "aws-load-balancer-controller"
          }
        },
        {
          namespace = "kube-system"
          labels = {
            "k8s-app" = "kube-dns"
          }
        }
      ]

      subnet_ids = module.vpc.private_subnets

      tags = merge(local.common_tags, {
        Name        = "${local.customer_workload_name}-${each.value}-kube-system-fargate"
        Environment = each.value
        Purpose     = "eks-system-fargate-profile"
      })
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

      tags = merge(local.common_tags, {
        Name        = "${local.customer_workload_name}-${each.value}-application-fargate"
        Environment = each.value
        Purpose     = "eks-application-fargate-profile"
      })
    }

    # AWS observability namespace for logging
    aws_observability = {
      name = "${each.value}-aws-observability"
      selectors = [
        {
          namespace = "aws-observability"
        }
      ]

      subnet_ids = module.vpc.private_subnets

      tags = merge(local.common_tags, {
        Name        = "${local.customer_workload_name}-${each.value}-observability-fargate"
        Environment = each.value
        Purpose     = "eks-observability-fargate-profile"
      })
    }
  }

  # EKS managed add-ons
  cluster_addons = {
    coredns = {
      configuration_values = jsonencode({
        computeType = "Fargate"
        # Ensure CoreDNS runs on Fargate
        nodeSelector = {
          "kubernetes.io/os" = "linux"
        }
        tolerations = [
          {
            key      = "CriticalAddonsOnly"
            operator = "Exists"
          }
        ]
      })
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          # Enable prefix delegation for more IP addresses per pod
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }

    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  # Access entries for cluster access
  access_entries = {
    # Admin access for the current user/role
    admin = {
      kubernetes_groups = []
      principal_arn     = data.aws_caller_identity.current.arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = merge(local.common_tags, {
    Name        = "${local.customer_workload_name}-${each.value}-eks"
    Environment = each.value
    Purpose     = "eks-fargate-cluster"
  })
}

############################
# KMS KEYS FOR EKS ENCRYPTION
############################

# KMS key for EKS cluster encryption per environment
resource "aws_kms_key" "eks" {
  for_each = toset(var.workload_environments)

  description             = "EKS cluster encryption key for ${each.value} environment"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name        = "${local.customer_workload_name}-${each.value}-eks-encryption"
    Environment = each.value
    Purpose     = "eks-cluster-encryption"
  })
}

# KMS key alias for easier identification
resource "aws_kms_alias" "eks" {
  for_each = toset(var.workload_environments)

  name          = "alias/${replace(local.customer_workload_name, ".", "-")}-${each.value}-eks"
  target_key_id = aws_kms_key.eks[each.value].key_id
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
      name                                 = each.value
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }

  depends_on = [module.eks]
}

# Create AWS observability namespace for Fluent Bit logging
resource "kubernetes_namespace" "aws_observability" {
  for_each = toset(var.workload_environments)

  metadata {
    name = "aws-observability"
    labels = {
      name                = "aws-observability"
      "aws-observability" = "enabled"
    }
  }

  depends_on = [module.eks]
}

############################
# FARGATE LOGGING CONFIGURATION
############################

# ConfigMap for Fargate Fluent Bit logging
resource "kubernetes_config_map" "aws_logging" {
  for_each = toset(var.workload_environments)

  metadata {
    name      = "aws-logging"
    namespace = "aws-observability"
  }

  data = {
    "output.conf" = <<-EOT
      [OUTPUT]
          Name cloudwatch_logs
          Match *
          region ${local.aws_region}
          log_group_name /aws/eks/${module.eks[each.value].cluster_name}/fargate
          log_stream_prefix fargate-
          auto_create_group true
    EOT

    "parsers.conf" = <<-EOT
      [PARSER]
          Name cri
          Format regex
          Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>[^ ]*) (?<message>.*)$
          Time_Key time
          Time_Format %Y-%m-%dT%H:%M:%S.%L%z
    EOT

    "filters.conf" = <<-EOT
      [FILTER]
          Name parser
          Match *
          Key_Name log
          Parser cri
    EOT
  }

  depends_on = [kubernetes_namespace.aws_observability]
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