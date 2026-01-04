############################
# EKS CLUSTER
############################

# EKS Cluster using terraform-aws-modules/eks/aws
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${local.customer_workload_name}-eks"
  cluster_version = "1.28"

  # Cluster endpoint configuration
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # VPC and subnet configuration
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # Cluster encryption
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    main = {
      name = "${local.customer_workload_name}-main"

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 10
      desired_size = 3

      # Use latest EKS optimized AMI
      ami_type = "AL2_x86_64"

      # Node group configuration
      disk_size = 50

      # Enable detailed monitoring
      enable_monitoring = true

      # Taints and labels
      labels = {
        Environment = var.customer_workload_environment
        NodeGroup   = "main"
      }

      # Update configuration
      update_config = {
        max_unavailable_percentage = 25
      }

      # Launch template configuration
      create_launch_template = false
      launch_template_name   = ""

      # Security group rules
      remote_access = {
        ec2_ssh_key               = var.eks_node_ssh_key_name
        source_security_group_ids = [aws_security_group.eks_remote_access.id]
      }

      tags = {
        Name        = "${local.customer_workload_name}-main-node-group"
        Environment = var.customer_workload_environment
        Purpose     = "eks-worker-nodes"
      }
    }
  }

  # Cluster add-ons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Cluster access entries
  access_entries = {
    admin = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${local.aws_account_id}:root"

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

  tags = {
    Name        = "${local.customer_workload_name}-eks"
    Environment = var.customer_workload_environment
    Purpose     = "kubernetes-cluster"
  }
}

############################
# KMS KEY FOR EKS ENCRYPTION
############################

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key for ${local.customer_workload_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${local.customer_workload_name}-eks-encryption"
    Environment = var.customer_workload_environment
    Purpose     = "eks-encryption"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${local.customer_workload_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

############################
# SECURITY GROUPS
############################

# Security group for remote access to EKS nodes
resource "aws_security_group" "eks_remote_access" {
  name_prefix = "${local.customer_workload_name}-eks-remote-access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH access for EKS nodes"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.customer_workload_name}-eks-remote-access"
    Environment = var.customer_workload_environment
    Purpose     = "eks-remote-access"
  }
}

############################
# IAM ROLES FOR SERVICE ACCOUNTS (IRSA)
############################

# IAM role for AWS Load Balancer Controller
module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.customer_workload_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Name        = "${local.customer_workload_name}-aws-load-balancer-controller"
    Environment = var.customer_workload_environment
    Purpose     = "aws-load-balancer-controller"
  }
}

# IAM role for EBS CSI Driver
module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.customer_workload_name}-ebs-csi-controller"

  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {
    Name        = "${local.customer_workload_name}-ebs-csi-controller"
    Environment = var.customer_workload_environment
    Purpose     = "ebs-csi-driver"
  }
}

# IAM role for Cluster Autoscaler
module "cluster_autoscaler_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.customer_workload_name}-cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = {
    Name        = "${local.customer_workload_name}-cluster-autoscaler"
    Environment = var.customer_workload_environment
    Purpose     = "cluster-autoscaler"
  }
}

############################
# KUBERNETES PROVIDER CONFIGURATION
############################

# Configure Kubernetes provider to interact with EKS cluster
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally.
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Configure Helm provider
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

############################
# AWS LOAD BALANCER CONTROLLER
############################

# Install AWS Load Balancer Controller using Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.2"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [
    module.eks.eks_managed_node_groups,
    module.aws_load_balancer_controller_irsa_role
  ]
}

############################
# CLUSTER AUTOSCALER
############################

# Install Cluster Autoscaler using Helm
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.29.0"

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cluster_autoscaler_irsa_role.iam_role_arn
  }

  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = "10m"
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = "10m"
  }

  depends_on = [
    module.eks.eks_managed_node_groups,
    module.cluster_autoscaler_irsa_role
  ]
}