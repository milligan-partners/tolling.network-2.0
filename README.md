# Tolling.Network 2.0

A distributed ledger solution for toll interoperability, built on Hyperledger Fabric.

Tolling.Network enables transportation agencies to share toll transaction data, reconcile charges, and manage electronic toll accounts across jurisdictions using a permissioned blockchain network.

## Architecture

| Layer | Technology |
|---|---|
| Blockchain | Hyperledger Fabric 2.5.x LTS |
| Smart Contracts | Go (contractapi) |
| Client SDK | @hyperledger/fabric-gateway |
| REST API | NestJS + TypeScript (Node.js 20) |
| State Database | CouchDB |
| Infrastructure | GKE + Terraform + Hyperledger Bevel |

## Repository Structure

```
chaincode/          Smart contracts (Go) — CTOC and NIOP protocols
api/                REST API server (NestJS/TypeScript)
infrastructure/     Docker, Kubernetes, Terraform, and Bevel configs
network-config/     Fabric channel, crypto, and collections configuration
tools/              Data generation, CouchDB queries, and admin scripts
docs/               Architecture decisions, protocol references, onboarding
_legacy/            Archived code from v1.x repositories (reference only)
```

## Supported Protocols

- **CTOC** (California Toll Operators Committee) — California agency interoperability
- **NIOP** (National Interoperability) — National toll agency interoperability

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Go 1.22+
- Node.js 20 LTS
- Python 3.8+ (for data generation tools)

### Local Development

```bash
# Start the local Fabric network
make docker-up

# Run chaincode tests
make chaincode-test

# Start the API server
make api-dev

# Generate test data
make generate-data

# Tear down the network
make docker-down
```

## Documentation

- [Architecture Overview](docs/architecture/README.md)
- [Local Development Setup](docs/onboarding/local-dev-setup.md)
- [NIOP Protocol Reference](docs/protocols/niop-reference.md)
- [CTOC Protocol Reference](docs/protocols/ctoc-reference.md)
- [API Schema](docs/api/contract-schema.json)

## License

This project is licensed under the Apache License 2.0 — see [LICENSE](LICENSE) for details.
