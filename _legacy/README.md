# Legacy Code Archive

This directory contains full copies of the original Tolling.Network v1.x repositories, preserved for reference during the 2.0 rewrite. The `.git` directories and generated crypto material have been excluded.

## Contents

| Directory | Original Repo | Purpose |
|---|---|---|
| `Tolling.Network-PoC/` | milligan-partners/Tolling.Network-PoC | Proof of concept — Fabric 1.1, K8s deployment, 999-account test dataset |
| `Tolling.Network/` | milligan-partners/Tolling.Network | Main platform — multi-env deployment, ELK pipeline, private data collections |
| `private-dev/` | milligan-partners/private-dev | Dev environment — Express API, CouchDB queries, team docs |
| `chaincode/` | milligan-partners/chaincode | Smart contracts — CTOC, NIOP, and PoC chaincodes (Node.js) |
| `elastic-chain/` | milligan-partners/elastic-chain | ELK integration — Docker Compose, data generation, Logstash pipeline |
| `NodeSDK/` | milligan-partners/NodeSDK | REST API/SDK — Express MVC, NIOP/CTOC models, JWT auth |

## What Was Extracted

Files that are still useful have been copied to their new locations in the 2.0 monorepo:

- **Test data** (`account.json`, `tags.json`, `toll_charges.json`) -> `chaincode/testdata/`
- **Collections configs** -> `chaincode/*/collections_config.json` and `network-config/collections/`
- **Network configs** (`configtx.yaml`, `crypto-config.yaml`) -> `network-config/`
- **Docker/ELK configs** -> `infrastructure/docker/`
- **K8s manifests** -> `infrastructure/k8s/`
- **Data generation scripts** -> `tools/data-generation/`
- **CouchDB query scripts** -> `tools/couchdb-queries/`
- **Admin scripts** (`enrollAdmin.js`, etc.) -> `tools/scripts/`
- **NIOP XML samples** -> `chaincode/testdata/niop-samples/`
- **Documentation** -> `docs/`

## Note

This directory can be removed once the 2.0 rewrite is complete and the team confirms nothing else is needed from the original code.
