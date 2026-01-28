# CLAUDE.md — Project Context for Tolling.Network 2.0

## What This Project Is

Tolling.Network is an open-source Hyperledger Fabric blockchain for US toll interoperability. It replaces the current hub-and-spoke batch processing model (nightly SFTP/XML file transfers between agencies and regional hubs) with a shared, permissioned ledger where toll agencies transact directly.

**Owner:** Milligan Partners
**License:** Apache-2.0
**Repo:** milligan-partners/tolling.network-2.0

## Architecture Decisions

### Option C: Hub-Compatible, Agency-Native
- Every agency is a first-class Fabric organization (own peers, own CA, own identity)
- Hubs are optional aggregators, not required middlemen
- NIOP/IAG/CTOC protocols are implemented as chaincode validation rules, not infrastructure
- Two connectivity modes: **direct** (agency runs own Fabric peers) and **hub-routed** (hub operates peers on agency's behalf — operational choice, not architectural difference)
- Consortiums are governance layers (Fabric channels with shared chaincode), not routing layers

### Data Model Design Principles
- **Toll-first, mobility-open** — Core entity is "Charge" (not "TollCharge") to support future congestion pricing, parking, transit, MBUF
- **No PII on ledger** — Customer details stay in agency back-office systems; ledger carries only interoperability metadata

## Tech Stack

| Layer | Technology |
|---|---|
| Blockchain | Hyperledger Fabric 2.5.x LTS |
| Chaincode | Go (using contractapi) |
| Client SDK | @hyperledger/fabric-gateway v1.10.0 |
| API | NestJS + TypeScript on Node.js 20 LTS |
| State DB | CouchDB |
| Infrastructure | Terraform (GKE), Hyperledger Bevel, Docker Compose (local dev) |
| CI/CD | GitHub Actions |
| Secrets | GCP Secret Manager |

## Domain Concepts

### Industry Structure
- **NIOP** — National Interoperability, defines rules for cross-hub data exchange
- **Four regional hubs:** E-ZPass/EZIOP (39 agencies, Northeast), CUSIOP (Central US — TX, KS, OK), SEIOP (Southeast, anchored by Florida CSC), WRTO/FasTrak (Western/California)
- **Agencies** — Individual toll operators (e.g., TCA, NTTA, HCTRA, BATA, PANYNJ)

### Key Protocols
- **NIOP ICD** — National interop record types: TB01, TC01, TC02, VB01, VC01, VC02 (suffix `A` for corrections)
- **IAG Inter-CSC** — E-ZPass file format spec (versions 1.51n, 1.60)
- **CTOC** — California/Western region tech spec (Rev A), reports: CTOC-1, CTOC-2, CTOC-5, CTOC-6

### Core Entities
Agency, Account, Tag, Charge, Correction, Reconciliation, Acknowledgement, Settlement

### Posting Disposition Codes
P (posted), D (duplicate), I (invalid), N (not posted), S (system issue), T (format error), C (not on file), O (too old)

### Acknowledgement Return Codes
00 (success) through 13 (see NIOP ICD spec)

## Fabric Network Topology

### Channels
- `national` — Agency registry, protocol versions, reference data
- `ezpass` — E-ZPass consortium governance (IAG rules)
- `cusiop` — CUSIOP consortium governance
- `seiop` — SEIOP consortium governance
- `wrto` — WRTO/FasTrak governance (CTOC rules)
- `interop` — Cross-consortium charge exchange, reconciliation, settlement

### Private Data Collections
- `tvl_{homeAgency}` — Tag Validation List (home agency + all away agencies)
- `charges_{agencyA}_{agencyB}` — Bilateral charge/correction/recon/settlement data
- `hub_aggregate_{hubID}` — Aggregated reporting for hub-routed transactions

## Repo Structure

```
tolling-network-2.0/
├── chaincode/
│   ├── ctoc/          # Go chaincode for California interop
│   ├── niop/          # Go chaincode for National interop
│   ├── shared/        # Shared Go code (encryption, lookups)
│   └── testdata/      # Test fixtures (accounts, tags, charges)
├── api/               # NestJS REST API
├── infrastructure/
│   ├── terraform/     # GKE provisioning
│   ├── bevel/         # Hyperledger Bevel config
│   ├── docker/        # Local dev (docker-compose)
│   └── k8s/           # Kubernetes manifests
├── network-config/    # Fabric configtx, crypto-config, collections
├── tools/             # Data generation, CouchDB queries, scripts
├── docs/
│   ├── architecture/  # Mermaid diagrams (.mmd files)
│   ├── onboarding/    # Developer setup
│   ├── api/           # Contract schema
│   └── protocols/     # NIOP/CTOC reference
├── design-style-guides/
├── industry-specs/    # (gitignored) Proprietary NIOP/IAG/CTOC specs
├── plan.md            # Product & development plan (8 sections)
└── EVALUATION.md      # Assessment of legacy repos
```

## Coding Conventions

### Go Chaincode
- Use Hyperledger Fabric `contractapi` package
- One chaincode package per protocol domain (niop, ctoc)
- Shared utilities in `chaincode/shared/`
- Models in `models/` subdirectory within each chaincode
- CouchDB indexes in `META-INF/statedb/couchdb/indexes/`
- Real encryption (the legacy code had no-op encryption stubs)

### TypeScript API
- NestJS module structure: auth, transactions, niop, ctoc, network
- Fabric Gateway client in `src/fabric/` service
- Node.js 20 LTS

### General
- No PII in any committed file
- Industry specs are gitignored (proprietary documents)
- Apache-2.0 license, Copyright 2016-2026 Milligan Partners

## Current Status

Working through `plan.md` — an 8-section product and development plan:
1. Value Proposition — drafted
2. Data Model — drafted (with Option C architecture, entity definitions, channel design)
3. Roadmap — next
4. Network Participants & Governance — stub
5. Privacy Model — stub
6. Integration Points — stub
7. Business Model — stub
8. Regulatory & Compliance — stub

Architecture diagrams are in `docs/architecture/*.mmd` (Mermaid format).

## Legacy Context

This project consolidates 7 abandoned/stalled repos from 2016-2023:
- elastic-chain (PoC docker network)
- HLF-chaincode (Go chaincode, no-op encryption)
- NodeSDK (Express API, NIOP XML parsing)
- private-dev (team notes, K8s configs, CouchDB queries)
- Tolling-Network (original repo, GPL-licensed)
- PoC (999 test accounts)
- Tolling.Network-2.0 (empty placeholder)

All had zero tests, no CI/CD, and incomplete implementations. See `EVALUATION.md` for details.
