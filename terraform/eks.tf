module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.24.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_private_access                  = true
  endpoint_public_access                   = true
  endpoint_public_access_cidrs             = var.cluster_endpoint_public_access_cidrs
  enable_cluster_creator_admin_permissions = true

  # Karpenter uses EKS Pod Identity, so an IRSA OIDC provider is unnecessary.
  enable_irsa = false

  upgrade_policy = {
    support_type = "STANDARD"
  }

  encryption_config = null

  addons = {
    coredns                = {}
    eks-pod-identity-agent = { before_compute = true }
    kube-proxy             = {}
    vpc-cni                = { before_compute = true }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Karpenter must run on capacity that it does not manage itself. It can run
  # on EKS Fargate, but this POC uses a small managed node group for simplicity.
  eks_managed_node_groups = {
    system = {
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 3
      desired_size = 2

      labels = {
        "karpenter.sh/controller" = "true"
      }

      # Reserve these nodes for Karpenter and other critical cluster add-ons.
      taints = {
        critical_addons = {
          key    = "CriticalAddonsOnly"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  tags = local.tags
}
