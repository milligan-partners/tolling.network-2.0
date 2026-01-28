# Hyperledger Bevel

Hyperledger Bevel automates the deployment and management of Hyperledger Fabric networks on Kubernetes.

## Setup

The `network.yaml` file defines the complete Fabric network topology for deployment via Bevel.

See: https://hyperledger-bevel.readthedocs.io/en/latest/guides/fabric/deploy-fabric-operator/

## Why Bevel

- Declarative network definition (YAML)
- Kubernetes-native via bevel-operator-fabric
- Supports Fabric 2.5.x and 3.x
- Integrates with HashiCorp Vault for secret management
- GitOps workflow with Flux
