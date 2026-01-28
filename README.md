# Tolling.Network 2.0

A distributed ledger for US toll interoperability, built on Hyperledger Fabric.

Tolling.Network replaces the hub-and-spoke batch processing model used by toll agencies today — nightly SFTP transfers, XML files, 30-day settlement cycles — with a shared, permissioned blockchain where agencies transact directly in near-real-time.

## The Problem

US toll interoperability is fragmented across four regional consortiums (E-ZPass, CUSIOP, SEIOP, WRTO/FasTrak) coordinated through NIOP. Each agency runs its own back-office system. Data exchange happens via batch file transfers. Tag validation lists take 24-72 hours to propagate. Settlement lags 30-45 days. There is no shared source of truth.

Congress mandated nationwide interoperability in 2012 (MAP-21). A decade later, it remains incomplete.

## The Approach

**Hub-compatible, agency-native.** Every toll agency is a first-class Fabric organization — own peers, own certificate authority, own identity. Agencies can transact directly with any other agency on the network. Existing hubs can participate as optional aggregators, not required middlemen. The system speaks NIOP, IAG, and CTOC data formats natively as chaincode validation rules.

**Layered governance as code.** Smart contracts encode business rules at three levels — agency, consortium, and national — matching how the industry actually operates. Compliance is enforced through Fabric endorsement policies, not committee politics.

**No PII on the ledger.** Customer details stay in agency back-office systems. The ledger carries only interoperability metadata: charges, reconciliation, settlement.

## Architecture

| Layer | Technology |
|---|---|
| Blockchain | Hyperledger Fabric 2.5.x LTS |
| Smart Contracts | Go (contractapi) |
| Client SDK | @hyperledger/fabric-gateway v1.10.0 |
| REST API | NestJS + TypeScript (Node.js 20 LTS) |
| State Database | CouchDB |
| Infrastructure | GKE + Terraform + Hyperledger Bevel |
| CI/CD | GitHub Actions |

### Network Topology

```
┌─────────────────────────────────────────────────────┐
│                  NATIONAL CHANNEL                    │
│              Agency Registry + Versioning            │
└──┬──────────┬──────────┬──────────┬──────────┬──────┘
   │          │          │          │          │
┌──┴───┐  ┌──┴───┐  ┌──┴───┐  ┌──┴───┐  ┌──┴──────────────┐
│E-ZPass│  │CUSIOP│  │ WRTO │  │SEIOP │  │  INTEROP CHANNEL │
│  IAG  │  │      │  │FasTrak│  │      │  │  Cross-Consortium│
│ Rules │  │Rules │  │ CTOC │  │Rules │  │  Charges, Recon,  │
│       │  │      │  │Rules │  │      │  │  Settlement       │
└───────┘  └──────┘  └──────┘  └──────┘  │                   │
                                          │  Private Data:    │
                                          │  tvl_{agency}     │
                                          │  charges_{A}_{B}  │
                                          └───────────────────┘
```

### Core Data Model

- **Agency** — Organizational unit (toll operator, hub, or clearinghouse)
- **Tag** — Transponder linked to an account, shared via Tag Validation Lists
- **Charge** — A toll or mobility event between an away agency and a home agency
- **Correction** — Amendment to a previously submitted charge
- **Reconciliation** — Home agency's posting response (disposition P/D/I/N/S/T/C/O)
- **Settlement** — Period-based financial netting between two agencies
- **Acknowledgement** — Protocol-level receipt confirmation

See [plan.md](plan.md) for the full data model, entity definitions, and architecture decisions.

## Repository Structure

```
chaincode/          Go smart contracts — NIOP and CTOC protocol validation
  niop/             National interop chaincode
  ctoc/             California/Western region chaincode
  shared/           Shared Go utilities (encryption, lookups)
  testdata/         Test fixtures (accounts, tags, charges)
api/                NestJS REST API (TypeScript)
infrastructure/
  docker/           Local dev environment (docker-compose)
  terraform/        GKE cluster provisioning
  bevel/            Hyperledger Bevel configuration
  k8s/              Kubernetes manifests
network-config/     Fabric configtx, crypto-config, collection configs
tools/              Data generation, CouchDB queries, admin scripts
docs/
  architecture/     Mermaid diagrams (.mmd) — ER, topology, lifecycle, privacy
  onboarding/       Developer setup guides
  protocols/        NIOP/CTOC reference
  api/              Contract schema
design-style-guides/  Typography, color, component design system
```

## Supported Protocols

| Protocol | Scope | Record Types |
|---|---|---|
| **NIOP ICD** | National interop | TB01, TC01, TC02, VB01, VC01, VC02 |
| **IAG Inter-CSC** | E-ZPass consortium | v1.51n, v1.60 file formats |
| **CTOC** | Western/California | CTOC-1, CTOC-2, CTOC-5, CTOC-6 reports |

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

- [Architecture Diagrams](docs/architecture/) — Mermaid source files
- [Contributing](CONTRIBUTING.md)

## Status

This project is in active planning and early development.

## License

Apache License 2.0 — see [LICENSE](LICENSE).

Copyright 2016-2026 Milligan Partners.
