# EKS with Karpenter, Graviton, and Spot

This Terraform configuration creates:

- a dedicated VPC in `us-east-1`
- an Amazon EKS cluster
- Karpenter with Spot workload capacity
- x86 (`amd64`) and Graviton (`arm64`) support

## Prerequisites

- Terraform 1.14.3
- AWS CLI v2
- `kubectl`
- AWS credentials with sufficient permissions

## Deploy

Confirm the target AWS account:

```bash
aws sts get-caller-identity
```

Initialize and deploy:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Configure `kubectl`:

```bash
mkdir -p "$HOME/.kube"
export KUBECONFIG="$HOME/.kube/$(terraform output -raw cluster_name)"

aws eks update-kubeconfig \
  --region "$(terraform output -raw aws_region)" \
  --name "$(terraform output -raw cluster_name)" \
  --kubeconfig "$KUBECONFIG"

kubectl get nodes
```

## Verify Karpenter

```bash
kubectl -n kube-system get pods -l app.kubernetes.io/name=karpenter
kubectl get ec2nodeclass
kubectl get nodepool
```

Expected custom resources:

```text
EC2NodeClass/default
NodePool/default
```

## Run workloads on x86 or Graviton

Developers select the processor architecture in their pod template. For x86:

```yaml
nodeSelector:
  kubernetes.io/arch: amd64
  karpenter.sh/nodepool: default
```

For AWS Graviton:

```yaml
nodeSelector:
  kubernetes.io/arch: arm64
  karpenter.sh/nodepool: default
```

The container image must support the selected architecture. The included examples use a multi-architecture Amazon Linux image:

```bash
kubectl apply -f examples/amd64-deployment.yaml
kubectl apply -f examples/arm64-deployment.yaml
kubectl get pods -o wide --watch
```

Verify node architecture and capacity type:

```bash
kubectl get nodes \
  -L kubernetes.io/arch,karpenter.sh/capacity-type,karpenter.sh/nodepool
```

Verify architecture inside the containers:

```bash
kubectl exec deploy/demo-amd64 -- uname -m
kubectl exec deploy/demo-arm64 -- uname -m
```

Expected output:

```text
x86_64
aarch64
```

## Destroy

```bash
kubectl delete -f examples/amd64-deployment.yaml --ignore-not-found
kubectl delete -f examples/arm64-deployment.yaml --ignore-not-found
terraform destroy
```

This environment creates billable AWS resources. Destroy it after testing.
