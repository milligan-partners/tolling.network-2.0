# GCP Infrastructure (GKE)

Terraform configuration for deploying Fabric components on Google Kubernetes Engine.

## Components Deployed

- **GKE Cluster:** Regional cluster with 3 nodes (e2-standard-4)
- **Org1:** 2 peer nodes + 1 Fabric CA
- **Org4:** 2 peer nodes + 1 Fabric CA
- **Orderer:** 2 of 5 Raft orderer nodes
- **CouchDB:** State database for each peer
- **Monitoring:** Cloud Monitoring + Cloud Logging integration

## Prerequisites

```bash
# Authenticate with GCP
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable compute.googleapis.com
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
gcloud container clusters get-credentials tolling-network-dev --region us-west1
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP project ID | (required) |
| `region` | GCP region | `us-west1` |
| `cluster_name` | GKE cluster name | `tolling-network` |
| `node_count` | Nodes per zone | `1` |
| `machine_type` | Node machine type | `e2-standard-4` |

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_endpoint` | GKE API server endpoint |
| `org1_peer_endpoints` | Org1 peer gRPC endpoints |
| `org4_peer_endpoints` | Org4 peer gRPC endpoints |
| `orderer_endpoints` | Orderer gRPC endpoints |

## Cost Estimate

| Component | Monthly Cost |
|-----------|--------------|
| GKE cluster (3x e2-standard-4) | $200 |
| Load balancers (4) | $80 |
| Persistent disks (200GB SSD) | $34 |
| Cloud NAT | $30 |
| **Total** | **~$344** |

## Security

- Workload Identity enabled for pod-level IAM
- Private cluster with Cloud NAT for egress
- Secret Manager for Fabric cryptographic material
- Network policies restricting pod-to-pod traffic
