############################
# EKS CLUSTER
############################

# EKS Cluster using terraform-aws-modules/eks/aws
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0" # Use v19 which is compatible with AWS provider 5.x

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
  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

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
# IAM ROLES FOR SERVICE ACCOUNTS (IRSA)
############################

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