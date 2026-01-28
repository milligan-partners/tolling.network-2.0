# Tolling.Network 2.0

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Go](https://img.shields.io/badge/Go-1.22+-00ADD8.svg)](#quick-start)
[![Hyperledger Fabric](https://img.shields.io/badge/Hyperledger_Fabric-2.5.x-2F3134.svg)](https://hyperledger-fabric.readthedocs.io/)

A distributed ledger for US toll interoperability, built on Hyperledger Fabric.

This is the successor to the original Tolling.Network proof-of-concept, rebuilt from the ground up with production-grade architecture.

Tolling.Network replaces the file-based processing models used by toll agencies today — whether hub-and-spoke or peer-to-peer transfers — with a shared, permissioned blockchain where agencies transact directly in near-real-time.

## Background

US toll interoperability is coordinated across regional consortiums through a national interoperability effort. Each agency runs its own back-office system. Data exchange happens via file transfers. There is no shared source of truth.

### Approach

**Hub-compatible, agency-native.** Every toll agency is a first-class Fabric organization — own peers, own certificate authority, own identity. Agencies can transact directly with any other agency on the network. Existing hubs participate as optional aggregators, not required middlemen. The system can speak NIOP, IAG, CTOC, and other data formats natively as chaincode validation rules.

**Layered governance as code.** Smart contracts encode business rules at three levels — agency, consortium, and national — matching how the industry actually operates. Compliance is enforced through Fabric endorsement policies, not committee politics.

**No PII on the ledger.** Customer details stay in agency back-office systems. The ledger carries only interoperability metadata: charges, reconciliation, settlement.

## Tech Stack

| Layer | Technology |
|---|---|
| Blockchain | Hyperledger Fabric 2.5.x LTS |
| Smart Contracts | Go (contractapi) |
| Client SDK | @hyperledger/fabric-gateway v1.10.0 |
| REST API | NestJS + TypeScript (Node.js 20 LTS) |
| State Database | CouchDB |
| Infrastructure | Multi-cloud (GKE, EKS, AKS) + Terraform |

## Quick Start

```bash
git clone https://github.com/milligan-partners/tolling-network-2.0.git
cd tolling-network-2.0

make network-init     # Generate crypto material
make docker-up        # Start Fabric network
make chaincode-test   # Run tests
make help             # See all commands
```

**Prerequisites:** Docker, Go 1.22+, Node.js 20 LTS

See [Getting Started](docs/onboarding/getting-started.md) for full setup instructions.

## Documentation

- [Architecture & Design](docs/architecture/design.md) — Data model, chaincode structure, indexing
- [Domain Glossary](docs/domain/glossary.md) — Industry terms and concepts
- [Developer Guide](docs/onboarding/getting-started.md) — Setup, testing, deployment

## Security

This project handles toll interoperability data for government transportation agencies. See [SECURITY.md](SECURITY.md) for our security policy.

To report a vulnerability, use [GitHub's private vulnerability reporting](https://github.com/milligan-partners/tolling.network-2.0/security/advisories/new).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow and code standards.

## Maintainers

- [Milligan](https://milligan.co) — [@matt5000](https://github.com/matt5000)

## License

[Apache License 2.0](LICENSE) — Copyright 2016-2026 Milligan Partners LLC.
