# AWS Infrastructure (EKS)

Terraform configuration for deploying Fabric components on Amazon Elastic Kubernetes Service.

## Components Deployed

- **EKS Cluster:** Managed control plane with 3 worker nodes (t3.xlarge)
- **Org2:** 2 peer nodes + 1 Fabric CA
- **Orderer:** 2 of 5 Raft orderer nodes
- **CouchDB:** State database for each peer
- **Monitoring:** CloudWatch Container Insights

## Prerequisites

```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity

# Install eksctl (optional, for cluster management)
brew install eksctl
```

## Usage

```bash
# Initialize
terraform init

# Plan (review changes)
terraform plan -var-file=dev.tfvars

# Apply
terraform apply -var-file=dev.tfvars

# Get kubeconfig
aws eks update-kubeconfig --name tolling-network-dev --region us-east-1
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `cluster_name` | EKS cluster name | `tolling-network` |
| `node_count` | Worker nodes | `3` |
| `instance_type` | Node instance type | `t3.xlarge` |

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_endpoint` | EKS API server endpoint |
| `org2_peer_endpoints` | Org2 peer gRPC endpoints |
| `orderer_endpoints` | Orderer gRPC endpoints |
| `cluster_security_group` | Security group for cross-cloud access |

## Cost Estimate

| Component | Monthly Cost |
|-----------|--------------|
| EKS control plane | $73 |
| EC2 nodes (3x t3.xlarge) | $150 |
| Network Load Balancer (2) | $45 |
| EBS volumes (200GB gp3) | $32 |
| NAT Gateway | $35 |
| **Total** | **~$335** |

## Security

- IRSA (IAM Roles for Service Accounts) enabled
- Private subnets with NAT Gateway
- Secrets Manager for Fabric cryptographic material
- Security groups restricting ingress to Fabric ports only
- Pod security standards enforced

## FedRAMP Considerations

For agencies requiring FedRAMP compliance:
- Deploy in `us-gov-west-1` or `us-gov-east-1` (GovCloud)
- Use FedRAMP-authorized services only
- Enable AWS Config rules for compliance monitoring
- Configure CloudTrail for audit logging
