module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "21.24.0"

  cluster_name = module.eks.cluster_name

  create_pod_identity_association = true
  enable_spot_termination         = true

  # The controller policy can exceed IAM's 6,144-character managed-policy
  # limit. The module's inline policy supports up to 10,240 characters.
  enable_inline_policy = true

  # New AWS accounts do not have the EC2 Spot service-linked role until the
  # first Spot request. Restrict creation to that specific AWS service.
  iam_policy_statements = [
    {
      sid       = "AllowEC2SpotServiceLinkedRoleCreation"
      actions   = ["iam:CreateServiceLinkedRole"]
      resources = ["arn:aws:iam::*:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot"]
      condition = [
        {
          test     = "StringEquals"
          variable = "iam:AWSServiceName"
          values   = ["spot.amazonaws.com"]
        }
      ]
    }
  ]

  node_iam_role_use_name_prefix = false
  node_iam_role_name            = local.karpenter_node_role_name

  tags = local.tags
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "kube-system"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  atomic  = true
  timeout = 900
  wait    = true

  values = [yamlencode({
    nodeSelector = {
      "karpenter.sh/controller" = "true"
    }
    tolerations = [
      {
        key      = "CriticalAddonsOnly"
        operator = "Exists"
        effect   = "NoSchedule"
      }
    ]
    settings = {
      clusterName       = module.eks.cluster_name
      clusterEndpoint   = module.eks.cluster_endpoint
      interruptionQueue = module.karpenter.queue_name
    }
  })]

  depends_on = [
    module.eks,
    module.karpenter,
    module.vpc,
  ]
}

# This local chart installs the EC2NodeClass and NodePool after Karpenter's CRDs exist.
resource "helm_release" "karpenter_config" {
  name      = "karpenter-config"
  namespace = "kube-system"
  chart     = "${path.module}/charts/karpenter-config"

  atomic  = true
  timeout = 600
  wait    = true

  values = [yamlencode({
    clusterName   = module.eks.cluster_name
    nodeRole      = local.karpenter_node_role_name
    capacityTypes = ["spot"]
    nodeTags = merge(local.tags, {
      ManagedBy = "karpenter"
    })
  })]

  depends_on = [helm_release.karpenter]
}
