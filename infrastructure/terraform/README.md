# Terraform Infrastructure

Multi-cloud Terraform configuration for Tolling.Network 2.0.

## Architecture

See [ADR-001: Multi-Cloud Infrastructure Strategy](../../docs/architecture/adr/001-multi-cloud-infrastructure.md) for the rationale behind the multi-cloud approach.

## Directory Structure

```
terraform/
├── modules/
│   ├── fabric-peer/      # Reusable module for Fabric peer deployment
│   ├── fabric-orderer/   # Reusable module for Fabric orderer nodes
│   └── fabric-ca/        # Reusable module for Fabric CA
├── gcp/                  # GKE cluster + Org1, Org4 peers + 2 orderers
├── aws/                  # EKS cluster + Org2 peer + 2 orderers
└── azure/                # AKS cluster + Org3 peer + 1 orderer
```

## Network Topology

| Organization | Cloud | Components |
|--------------|-------|------------|
| Orderer (distributed) | GCP + AWS + Azure | 5 Raft nodes (2 GCP, 2 AWS, 1 Azure) |
| Org1 | GCP (GKE) | 2 peers, 1 CA |
| Org2 | AWS (EKS) | 2 peers, 1 CA |
| Org3 | Azure (AKS) | 2 peers, 1 CA |
| Org4 | GCP (GKE) | 2 peers, 1 CA |

## Prerequisites

- Terraform >= 1.5.0
- Cloud provider CLIs authenticated:
  - `gcloud` for GCP
  - `aws` for AWS
  - `az` for Azure
- kubectl configured for each cluster

## Quick Start

```bash
# GCP
cd gcp
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

# AWS
cd ../aws
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

# Azure
cd ../azure
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

## Cross-Cloud Networking

Fabric peers and orderers communicate via gRPC with mutual TLS. Each node exposes a public endpoint with TLS certificates signed by the organization's Fabric CA.

For production deployments with stricter network isolation, consider:
1. VPN mesh between clouds (GCP Cloud VPN, AWS Site-to-Site VPN, Azure VPN Gateway)
2. Private connectivity services (GCP Private Service Connect, AWS PrivateLink, Azure Private Link)

## Cost Estimation

See ADR-001 for detailed cost breakdown. Development environment: ~$820/month across all three clouds.

## Secrets Management

Each cloud uses its native secrets manager:
- GCP: Secret Manager
- AWS: Secrets Manager
- Azure: Key Vault

Fabric cryptographic material (MSP, TLS certs) is stored in the respective secrets manager and mounted into Kubernetes pods.

For unified secrets management, consider HashiCorp Vault with cloud auto-unseal.
