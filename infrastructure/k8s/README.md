# Kubernetes Manifests

> **WARNING: LEGACY REFERENCE ONLY — DO NOT DEPLOY**

Legacy Kubernetes manifests ported from the v1.x `private-dev` repository (2019-2020).

## Security Issues

These manifests contain critical security problems and **must not be deployed**:

- **Fabric 1.1.0 images** — EOL since 2018, current LTS is 2.5.x
- **Docker socket mounted** in peer containers (`/var/run/`) — enables container escape
- **No security contexts** — all pods run as root
- **No NetworkPolicy** — unrestricted pod-to-pod communication
- **No RBAC** — no service accounts or role bindings
- **PVC on /tmp** — ephemeral storage, data loss on node reboot
- **Hardcoded external IP** in cronjob (`35.202.68.152`) — calls HTTP without auth
- **No resource limits** — containers can consume all cluster resources

## For Production

Use **Hyperledger Bevel** (see `../bevel/`) which provides:
- Fabric 2.5.x support
- TLS enabled by default
- External chaincode launcher (no docker socket)
- Proper security contexts and RBAC
- Raft ordering service

## Reference Value

These manifests are preserved only as reference for the deployment pipeline structure:
- Volume creation
- Artifact generation and copying
- Blockchain services (peers, orderer, CAs)
- Channel creation and joining
- Chaincode lifecycle (install, approve, commit)
