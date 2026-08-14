aws_region         = "us-east-1"
cluster_name       = "tech-assignment-eks"
vpc_cidr           = "10.80.0.0/19"
kubernetes_version = "1.36"
karpenter_version  = "1.14.0"

# Replace this with the reviewer's public IP/32 when restricting API access.
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
