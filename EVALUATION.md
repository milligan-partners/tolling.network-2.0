# Tolling.Network — Code & Product Evaluation

**Date:** January 27, 2026
**Scope:** All 7 repositories under milligan-partners GitHub organization

---

## Product Overview

Tolling.Network is a Hyperledger Fabric-based distributed ledger for toll interoperability between transportation agencies. The product enables agencies (e.g., TCA, BATA, SANDAG in California; TxDOT, HCTRA, NTTA nationally) to share toll transaction data, reconcile charges, and manage electronic toll accounts across jurisdictions.

---

## Repository-by-Repository Assessment

### 1. `Tolling.Network-PoC` — Proof of Concept (Public)

**Status: Abandoned prototype**

- **Last meaningful code change:** December 2019
- **Stack:** Hyperledger Fabric 1.1, Node.js chaincode, Kubernetes/GCP
- **What works:** Basic CRUD for accounts and transactions, Kubernetes deployment scripts, 999-record test dataset
- **Issues:** No tests, no-op encryption, incomplete `getamountOwed()` function with a variable reference bug, outdated dependencies (Node 8, Fabric 1.1), hardcoded business logic
- **Completeness:** ~80% of basic PoC features

### 2. `Tolling.Network` — Main Platform (Public)

**Status: Stalled**

- **Last commit:** July 2024 (data file updates only)
- **Stack:** Hyperledger Fabric 1.4, Node.js/Express API, CouchDB, ELK stack, Docker + Kubernetes
- **What works:** Multi-environment deployment (Docker single-node, Kubernetes), 4-org network, private data collections, ELK analytics pipeline
- **Issues:** Encryption function is a no-op (all "encrypted" data is plaintext), commented-out code blocks, undefined variables in chaincode, API endpoint that executes shell scripts (security risk), no tests
- **Completeness:** ~60% — architecture is solid but implementation has gaps

### 3. `private-dev` — Internal Development Environment (Private)

**Status: Inactive since ~2020**

- **Stack:** Same as Tolling.Network (Fabric, Docker, Kubernetes, Express)
- **Purpose:** Development sandbox with backend API server, CouchDB query scripts, Docker + Kubernetes deployment configs
- **What works:** Express API with 10+ endpoints, comprehensive bash scripts for CouchDB analytics, both Docker and Kubernetes deployments
- **Notable:** Contains team onboarding docs, architecture references, development roadmap
- **Issues:** No tests, hardcoded config, manual deployment only

### 4. `chaincode` — Smart Contracts (Private)

**Status: Abandoned since August 2020**

- **Contains 3 chaincodes:**
  - **CTOC** (California) — 281 lines, encryption is a no-op
  - **NIOP** (National) — 258 lines, will crash at runtime due to multiple undefined variable references (`state_lookup`, `plaza_lookup`, `key`)
  - **PoC** — 300 lines, most complete of the three
- **Issues:** Zero tests, critical runtime bugs in NIOP, no actual encryption anywhere, inconsistent error handling
- **Completeness:** CTOC ~70%, NIOP ~40% (broken), PoC ~80%

### 5. `elastic-chain` — ELK Integration (Private)

**Status: Abandoned since February 2020**

- **Stack:** Fabric 1.4, Docker Compose, ELK stack (Elasticsearch 6.7.1, Logstash, Kibana), Python data generation, Dremio
- **What works:** Full Docker environment with 11 services, CouchDB-to-Elasticsearch pipeline, Python synthetic data generator, parallel data bootstrapping
- **Issues:** Same no-op encryption bug, undefined `key` variable, commented-out code, no tests, outdated ELK versions
- **Completeness:** ~60% — good infrastructure, weak chaincode

### 6. `NodeSDK` — REST API / SDK (Private)

**Status: Abandoned since June 2019**

- **Stack:** Express.js, Fabric SDK 1.4, JWT auth, XML/JSON support, EJS templates
- **What works:** MVC architecture, 4 route groups (auth, tx, niop, ctoc), schema validation with schm/joi, Dockerfile
- **Issues:** Hardcoded credentials (`peer0`/`userpw`), missing JWT keys, model definition errors, zero tests despite having mocha/chai/sinon installed, no README
- **Completeness:** ~60% — skeleton is there but unfinished

### 7. `tolling.network-website` — Marketing Site (Private)

**Status: Empty stub**

- **Contains:** Only a README with the repo name
- **Single commit** from November 2018, never developed
- **Completeness:** 0%

---

## Overall Product Assessment

### Summary Table

| Repo | Status | Last Active Code | Tests | Production Ready |
|---|---|---|---|---|
| Tolling.Network-PoC | Abandoned | Dec 2019 | None | No |
| Tolling.Network | Stalled | ~2021 | None | No |
| private-dev | Inactive | ~2020 | None | No |
| chaincode | Abandoned | Aug 2020 | None | No |
| elastic-chain | Abandoned | Feb 2020 | None | No |
| NodeSDK | Abandoned | Jun 2019 | None | No |
| tolling.network-website | Empty | Never started | N/A | No |

### Critical Issues Across the Product

1. **No encryption anywhere.** Every repo has the same no-op `encrypt()` function. Sensitive data (tag IDs, plate numbers, account IDs) is stored in plaintext despite being routed through an "encrypt" call.

2. **Zero test coverage across all 7 repos.** No unit tests, no integration tests, no CI/CD pipelines.

3. **Runtime-crashing bugs.** The NIOP chaincode references undefined variables and will fail immediately on invocation.

4. **Severely outdated dependencies.** Hyperledger Fabric 1.1-1.4 (current is 2.5+), Node.js 8 (EOL since 2019), Elasticsearch 6.7.1.

5. **Code duplication.** The chaincode appears in multiple repos (Tolling.Network-PoC, Tolling.Network, chaincode, elastic-chain) with varying versions and no clear canonical source.

6. **No website.** The marketing site was never built.

### What's Solid

- **Architecture and design** — The multi-org Fabric network with private data collections is well-conceived for toll interoperability
- **Deployment infrastructure** — Both Docker and Kubernetes configs are comprehensive and functional
- **Data model** — The account/transaction/reconciliation data structures map well to real toll industry workflows
- **ELK integration** — The analytics pipeline from CouchDB through Logstash to Elasticsearch/Kibana is a good approach
- **Private data collections** — Proper use of Fabric's privacy features for multi-agency data isolation

### Product Maturity

The product reached early prototype stage around 2019-2020 and development stalled. The architecture demonstrates genuine understanding of toll interoperability challenges, but the implementation never reached a point where it could be deployed in production. The most recent activity (2024-2025) has been limited to documentation updates on the public repos.
