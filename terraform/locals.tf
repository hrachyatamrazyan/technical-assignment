locals {
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for index, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, index)]
  public_subnets  = [for index, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, index + 48)]

  karpenter_node_role_name = "${var.cluster_name}-karpenter-node"

  tags = {
    ManagedBy = "terraform"
  }
}
