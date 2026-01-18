# EKS Add-ons using terraform-aws-modules/eks-blueprints-addons
# Provides essential Kubernetes operational tools

############################
# EKS BLUEPRINTS ADD-ONS
############################

# EKS Blueprints add-ons for operational tooling
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  for_each = toset(var.workload_environments)

  cluster_name      = module.eks[each.value].cluster_name
  cluster_endpoint  = module.eks[each.value].cluster_endpoint
  cluster_version   = module.eks[each.value].cluster_version
  oidc_provider_arn = module.eks[each.value].oidc_provider_arn

  # AWS Load Balancer Controller - Essential for ALB creation
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    chart_version = "1.8.1"

    set = [
      {
        name  = "vpcId"
        value = module.vpc.vpc_id
      },
      {
        name  = "region"
        value = local.aws_region
      },
      {
        name  = "clusterName"
        value = module.eks[each.value].cluster_name
      }
    ]

    values = [
      yamlencode({
        controller = {
          service = {
            targetType = "ip" # Required for Fargate
          }
          nodeSelector = {
            "kubernetes.io/os" = "linux"
          }
          tolerations = [
            {
              key      = "CriticalAddonsOnly"
              operator = "Exists"
            }
          ]
        }
      })
    ]
  }

  # EFS CSI Driver for persistent storage (EBS not supported on Fargate)
  enable_aws_efs_csi_driver = true
  aws_efs_csi_driver = {
    chart_version = "3.1.1"

    values = [
      yamlencode({
        controller = {
          nodeSelector = {
            "kubernetes.io/os" = "linux"
          }
          tolerations = [
            {
              key      = "CriticalAddonsOnly"
              operator = "Exists"
            }
          ]
        }
      })
    ]
  }

  # AWS for Fluent Bit for container logging
  enable_aws_for_fluentbit = true
  aws_for_fluentbit = {
    chart_version = "0.1.32"

    set = [
      {
        name  = "cloudWatchLogs.region"
        value = local.aws_region
      },
      {
        name  = "cloudWatchLogs.logGroupName"
        value = "/aws/eks/${module.eks[each.value].cluster_name}/fargate"
      }
    ]

    values = [
      yamlencode({
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
    ]
  }

  # Cluster Autoscaler (for future managed node groups if needed)
  enable_cluster_autoscaler = false # Not needed for Fargate-only

  # Metrics Server for HPA
  enable_metrics_server = true
  metrics_server = {
    chart_version = "3.12.1"

    values = [
      yamlencode({
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
    ]
  }

  # Vertical Pod Autoscaler
  enable_vpa = true
  vpa = {
    chart_version = "4.5.0"

    values = [
      yamlencode({
        recommender = {
          nodeSelector = {
            "kubernetes.io/os" = "linux"
          }
          tolerations = [
            {
              key      = "CriticalAddonsOnly"
              operator = "Exists"
            }
          ]
        }
        updater = {
          nodeSelector = {
            "kubernetes.io/os" = "linux"
          }
          tolerations = [
            {
              key      = "CriticalAddonsOnly"
              operator = "Exists"
            }
          ]
        }
        admissionController = {
          nodeSelector = {
            "kubernetes.io/os" = "linux"
          }
          tolerations = [
            {
              key      = "CriticalAddonsOnly"
              operator = "Exists"
            }
          ]
        }
      })
    ]
  }

  tags = merge(local.common_tags, {
    Environment = each.value
    Purpose     = "eks-operational-addons"
  })

  depends_on = [module.eks]
}

############################
# KUBERNETES SERVICE ACCOUNTS
############################

# Service account for AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  for_each = toset(var.workload_environments)

  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = module.eks_blueprints_addons[each.value].aws_load_balancer_controller.iam_role_arn
    }
  }

  depends_on = [module.eks_blueprints_addons]
}

# Service account for EFS CSI Driver
resource "kubernetes_service_account" "efs_csi_controller" {
  for_each = toset(var.workload_environments)

  metadata {
    name      = "efs-csi-controller-sa"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = module.eks_blueprints_addons[each.value].aws_efs_csi_driver.iam_role_arn
    }
  }

  depends_on = [module.eks_blueprints_addons]
}

############################
# RBAC CONFIGURATION
############################

# ClusterRole for application namespace access
resource "kubernetes_cluster_role" "application_access" {
  for_each = toset(var.workload_environments)

  metadata {
    name = "${each.value}-application-access"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "secrets", "persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "daemonsets", "statefulsets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  depends_on = [module.eks]
}

# ClusterRoleBinding for application namespace access
resource "kubernetes_cluster_role_binding" "application_access" {
  for_each = toset(var.workload_environments)

  metadata {
    name = "${each.value}-application-access"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.application_access[each.value].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = each.value
  }

  depends_on = [kubernetes_namespace.application]
}

############################
# NETWORK POLICIES
############################

# Network policy for namespace isolation
resource "kubernetes_network_policy" "namespace_isolation" {
  for_each = toset(var.workload_environments)

  metadata {
    name      = "namespace-isolation"
    namespace = each.value
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress", "Egress"]

    # Allow ingress from same namespace
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = each.value
          }
        }
      }
    }

    # Allow ingress from kube-system (for system components)
    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
    }

    # Allow egress to same namespace
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = each.value
          }
        }
      }
    }

    # Allow egress to kube-system
    egress {
      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
    }

    # Allow egress to internet (for external APIs, registries, etc.)
    egress {
      to {}
      ports {
        protocol = "TCP"
        port     = "443"
      }
      ports {
        protocol = "TCP"
        port     = "80"
      }
      ports {
        protocol = "UDP"
        port     = "53"
      }
    }
  }

  depends_on = [kubernetes_namespace.application]
}