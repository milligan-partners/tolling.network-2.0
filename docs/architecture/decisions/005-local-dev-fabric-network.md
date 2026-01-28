# ADR-005: Local Development Fabric Network

## Status

Accepted

## Context

Epic 2 requires deployment infrastructure for the Tolling Network. The existing infrastructure code is legacy (Fabric 1.x, SOLO orderer, no TLS) and needs to be modernized to Fabric 2.5.x LTS.

We need a local development environment that:
1. Matches production topology closely enough for meaningful testing
2. Runs entirely in Docker Compose (no cloud dependencies)
3. Supports the chaincode already implemented (7 contracts, private data collections)
4. Enables integration testing against a real Fabric network

## Decision

### Network Topology

We implement a **4-org local network** with Raft ordering:

| Component | Count | Purpose |
|-----------|-------|---------|
| Orderer nodes | 3 | Raft consensus (crash fault tolerant) |
| Peer orgs | 4 | Org1, Org2, Org3, Org4 (generic names for dev) |
| Peers per org | 1 | Sufficient for local dev (production uses 2+) |
| CouchDB instances | 4 | One per peer for rich queries |
| Fabric CA | 1 | Shared CA for local dev simplicity |

### Fabric Version

**Fabric 2.5.x LTS** - Current long-term support release with:
- Raft ordering service
- External chaincode launcher
- Private data collection enhancements
- Gateway SDK support

### Security Configuration

Even in local dev, we enable security features to catch issues early:

| Feature | Local Dev | Production |
|---------|-----------|------------|
| TLS | Enabled | Enabled |
| Mutual TLS | Disabled | Enabled |
| Docker socket | Not mounted | Not mounted |
| CouchDB auth | Enabled | Enabled |

### Channel Structure

Single channel for local dev simplicity:

- **`tolling`** - All orgs joined, all chaincode deployed

Production will use the full 7-channel structure (national, ezpass, cusiop, seiop, wrto, interop, plus bilateral).

### Private Data Collections

Generate bilateral collections dynamically for the 4 orgs:
- `charges_Org1_Org2`, `charges_Org1_Org3`, `charges_Org1_Org4`
- `charges_Org2_Org3`, `charges_Org2_Org4`
- `charges_Org3_Org4`

Total: 6 bilateral collections (N*(N-1)/2 where N=4).

### Chaincode Deployment

Use **external chaincode launcher** (Fabric 2.x pattern):
- No Docker socket mounting in peers
- Chaincode runs as separate container
- Supports chaincode-as-a-service pattern

## Consequences

### Positive

- **Unblocks integration testing** - Can test chaincode against real Fabric network
- **Matches production patterns** - Raft, TLS, external chaincode
- **Fast iteration** - `make docker-up` starts network in ~60 seconds
- **Portable** - Any developer with Docker can run it

### Negative

- **Simplified topology** - 1 peer per org (production needs 2+ for HA)
- **Single CA** - Production uses per-org CAs
- **Single channel** - Production uses 7 channels with complex governance

### Neutral

- CouchDB ports exposed to host for debugging (production would not)
- Uses `cryptogen` for simplicity (production uses Fabric CA enrollment)

## Implementation

### Files to Create/Update

1. `infrastructure/docker/docker-compose.yaml` - Main network definition
2. `infrastructure/docker/.env.example` - Environment template
3. `network-config/configtx.yaml` - Channel/org configuration
4. `network-config/crypto-config.yaml` - Crypto material generation
5. `network-config/collections/collections_config.json` - Private data collections
6. `scripts/network-init.sh` - Network initialization
7. `scripts/deploy-chaincode.sh` - Chaincode deployment
8. `Makefile` - Updated targets

### Makefile Targets

```makefile
docker-up        # Start network, create channel, deploy chaincode
docker-down      # Stop and remove containers
docker-reset     # Full reset (remove volumes, regenerate crypto)
docker-logs      # Tail all container logs
integration-test # Run integration tests against local network
```

## References

- Hyperledger Fabric 2.5 Documentation: https://hyperledger-fabric.readthedocs.io/en/release-2.5/
- Fabric Samples test-network: https://github.com/hyperledger/fabric-samples/tree/main/test-network
- ADR-001: Bilateral Private Collections
