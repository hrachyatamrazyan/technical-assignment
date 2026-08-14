variable "aws_region" {
  description = "AWS Region for all resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS Region name, for example us-east-1."
  }
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string

  validation {
    condition     = length(var.cluster_name) <= 100 && can(regex("^[0-9A-Za-z][0-9A-Za-z_-]*$", var.cluster_name))
    error_message = "cluster_name must be 1-100 characters and contain only letters, numbers, hyphens, or underscores."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "kubernetes_version" {
  description = "EKS Kubernetes minor version."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must use major.minor format, for example 1.36."
  }
}

variable "karpenter_version" {
  description = "Karpenter Helm chart version."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.karpenter_version))
    error_message = "karpenter_version must use semantic version format, for example 1.14.0."
  }
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint."
  type        = list(string)

  validation {
    condition     = length(var.cluster_endpoint_public_access_cidrs) > 0 && alltrue([for cidr in var.cluster_endpoint_public_access_cidrs : can(cidrnetmask(cidr))])
    error_message = "cluster_endpoint_public_access_cidrs must contain at least one valid CIDR block."
  }
}
