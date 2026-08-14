output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "aws_region" {
  description = "AWS Region containing the cluster."
  value       = var.aws_region
}

output "vpc_id" {
  description = "ID of the dedicated VPC."
  value       = module.vpc.vpc_id
}
