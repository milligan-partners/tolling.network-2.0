# Azure Infrastructure (AKS)

Terraform configuration for deploying Fabric components on Azure Kubernetes Service.

## Components Deployed

- **AKS Cluster:** Managed cluster with 3 nodes (Standard_D4s_v3)
- **Org3:** 2 peer nodes + 1 Fabric CA
- **Orderer:** 1 of 5 Raft orderer nodes
- **CouchDB:** State database for each peer
- **Monitoring:** Azure Monitor for containers

## Prerequisites

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription YOUR_SUBSCRIPTION_ID

# Register required providers
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.KeyVault
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
az aks get-credentials --resource-group tolling-network-rg --name tolling-network-dev
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `location` | Azure region | `westus2` |
| `resource_group_name` | Resource group | `tolling-network-rg` |
| `cluster_name` | AKS cluster name | `tolling-network` |
| `node_count` | Worker nodes | `3` |
| `vm_size` | Node VM size | `Standard_D4s_v3` |

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_fqdn` | AKS API server FQDN |
| `org3_peer_endpoints` | Org3 peer gRPC endpoints |
| `orderer_endpoint` | Orderer gRPC endpoint |
| `key_vault_uri` | Key Vault URI for secrets |

## Cost Estimate

| Component | Monthly Cost |
|-----------|--------------|
| AKS (free control plane) | $0 |
| VMs (3x Standard_D4s_v3) | $180 |
| Load Balancer (Standard) | $20 |
| Managed Disks (200GB Premium) | $35 |
| NAT Gateway | $35 |
| **Total** | **~$270** |

## Security

- Azure AD pod identity enabled
- Private cluster with Azure Private Link
- Key Vault for Fabric cryptographic material
- Network Security Groups restricting traffic
- Azure Policy for Kubernetes

## Azure Government

For agencies requiring Azure Government:
- Deploy in `usgovvirginia` or `usgovarizona`
- Use Azure Government subscription
- Verify service availability in Government cloud
- Configure Azure Policy for compliance
