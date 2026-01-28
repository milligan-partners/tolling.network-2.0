# Kubernetes Manifests

Legacy Kubernetes manifests ported from the v1.x `private-dev` repository. These target Fabric 1.x on GKE and will need to be updated for Fabric 2.5.

For production deployment, use **Hyperledger Bevel** (see `../bevel/`).

These manifests are preserved as reference for the deployment pipeline structure:
- Volume creation
- Artifact generation and copying
- Blockchain services (peers, orderer, CAs)
- Channel creation and joining
- Chaincode lifecycle (install, approve, commit)
