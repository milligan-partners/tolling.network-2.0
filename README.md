# Tolling.Network 2.0

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Go](https://img.shields.io/badge/Go-1.22+-00ADD8.svg)](#install)
[![Hyperledger Fabric](https://img.shields.io/badge/Hyperledger_Fabric-2.5.x-2F3134.svg)](https://hyperledger-fabric.readthedocs.io/)

A distributed ledger for US toll interoperability, built on Hyperledger Fabric.

Tolling.Network replaces the file-based processing models used by toll agencies today — whether hub-and-spoke or peer-to-peer transfers — with a shared, permissioned blockchain where agencies transact directly in near-real-time.

## Table of Contents

- [Background](#background)
- [Install](#install)
- [Usage](#usage)
- [Architecture](#architecture)
- [Status](#status)
- [Security](#security)
- [Contributing](#contributing)
- [Maintainers](#maintainers)
- [License](#license)

## Background

US toll interoperability is fragmented across four regional consortiums (E-ZPass, CUSIOP, SEIOP, WRTO/FasTrak) coordinated through NIOP. Each agency runs its own back-office system. Data exchange happens via batch file transfers. Tag validation lists take 24-72 hours to propagate. Settlement lags 30-45 days. There is no shared source of truth.

Congress mandated nationwide interoperability in 2012 (MAP-21). Over a decade later, it remains incomplete.

### Approach

**Hub-compatible, agency-native.** Every toll agency is a first-class Fabric organization — own peers, own certificate authority, own identity. Agencies can transact directly with any other agency on the network. Existing hubs participate as optional aggregators, not required middlemen. The system speaks NIOP, IAG, and CTOC data formats natively as chaincode validation rules.

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

### Supported Protocols

| Protocol | Scope | Record Types |
|---|---|---|
| **NIOP ICD** | National interop | TB01, TC01, TC02, VB01, VC01, VC02 |
| **IAG Inter-CSC** | E-ZPass consortium | v1.51n, v1.60 file formats |
| **CTOC** | Western/California | CTOC-1, CTOC-2, CTOC-5, CTOC-6 reports |

## Install

### Prerequisites

- Docker and Docker Compose
- Go 1.22+
- Node.js 20 LTS (see `.nvmrc`)
- Python 3.8+ (for data generation tools)

### Setup

```bash
# Clone the repository
git clone https://github.com/milligan-partners/tolling-network-2.0.git
cd tolling-network-2.0

# Start the local Fabric network
make docker-up

# Run chaincode tests to verify setup
make chaincode-test
```

## Usage

```bash
# Show all available commands
make help

# Run the full test suite
make test

# Lint all code
make lint

# Generate synthetic test data
make generate-data

# Stop the network
make docker-down
```

### Repository Structure

```
chaincode/           Go smart contracts (NIOP feature-complete, CTOC stub)
api/                 NestJS REST API (scaffold)
infrastructure/      Docker, Terraform, Bevel, K8s configs
network-config/      Fabric channel and crypto configuration
tools/               Data generation and analytics scripts
docs/                Architecture diagrams, onboarding guides
```

See [docs/onboarding/](docs/onboarding/) for detailed documentation.

## Status

Active development. Chaincode is feature-complete for core NIOP protocol support.

| Component | Status | Coverage |
|-----------|--------|----------|
| Chaincode Models | Complete | 99.6% |
| Chaincode Contracts | Complete | 82.9% |
| Local Dev Environment | Complete | — |
| REST API | Scaffold | — |
| CI/CD | Planned | — |

All 7 domain entities implemented: Agency, Tag, Charge, Correction, Reconciliation, Acknowledgement, Settlement.

## Security

This project handles toll interoperability data for government transportation agencies. See [SECURITY.md](SECURITY.md) for our security policy and how to report vulnerabilities.

To report a vulnerability, use [GitHub's private vulnerability reporting](https://github.com/milligan-partners/tolling.network-2.0/security/advisories/new) rather than opening a public issue.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow, code standards, and security requirements.

## Maintainers

- [Milligan Partners LLC](https://github.com/milligan-partners)

## License

[Apache License 2.0](LICENSE) — Copyright 2016-2026 Milligan Partners LLC.
