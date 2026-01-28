# Deployment Guide

This document covers deploying the NIOP chaincode to a Hyperledger Fabric network.

## Prerequisites

- Hyperledger Fabric 2.5+ network running
- Peer and orderer nodes operational
- CouchDB configured as state database
- Channel created and peers joined

## Chaincode Packaging

### 1. Vendor Dependencies

```bash
cd chaincode/niop
go mod vendor
```

### 2. Package Chaincode

```bash
peer lifecycle chaincode package niop.tar.gz \
  --path ./chaincode/niop \
  --lang golang \
  --label niop_1.0
```

## Chaincode Installation

### Install on Each Peer

```bash
peer lifecycle chaincode install niop.tar.gz
```

### Verify Installation

```bash
peer lifecycle chaincode queryinstalled
```

Note the package ID (e.g., `niop_1.0:abc123...`).

## Private Data Collections

Before approving the chaincode, create the collections configuration.

### Collection Configuration (`collections_config.json`)

Each bilateral agency pair needs a collection:

```json
[
  {
    "name": "charges_AGENCY_A_AGENCY_B",
    "policy": "OR('AGENCY_A.member', 'AGENCY_B.member')",
    "requiredPeerCount": 1,
    "maxPeerCount": 2,
    "blockToLive": 0,
    "memberOnlyRead": true,
    "memberOnlyWrite": true
  }
]
```

### Generating Collections Config

For N agencies, generate N*(N-1)/2 collection entries:

```bash
# Example: agencies TCA, BATA, MTC
# Collections needed:
# - charges_BATA_MTC
# - charges_BATA_TCA
# - charges_MTC_TCA
```

## Chaincode Approval

### Approve for Organization

```bash
peer lifecycle chaincode approveformyorg \
  --channelID tolling-channel \
  --name niop \
  --version 1.0 \
  --package-id niop_1.0:abc123... \
  --sequence 1 \
  --collections-config collections_config.json \
  --signature-policy "OR('Org1MSP.member', 'Org2MSP.member')" \
  --init-required false
```

### Check Commit Readiness

```bash
peer lifecycle chaincode checkcommitreadiness \
  --channelID tolling-channel \
  --name niop \
  --version 1.0 \
  --sequence 1
```

## Chaincode Commit

Once enough organizations approve:

```bash
peer lifecycle chaincode commit \
  --channelID tolling-channel \
  --name niop \
  --version 1.0 \
  --sequence 1 \
  --collections-config collections_config.json \
  --peerAddresses peer0.org1.example.com:7051 \
  --peerAddresses peer0.org2.example.com:7051
```

## CouchDB Index Deployment

Indexes in `META-INF/statedb/couchdb/indexes/` are automatically deployed with the chaincode.

Verify indexes were created:

```bash
curl http://localhost:5984/channel_niop/_index
```

## Upgrading Chaincode

### 1. Package New Version

```bash
peer lifecycle chaincode package niop_v2.tar.gz \
  --path ./chaincode/niop \
  --lang golang \
  --label niop_2.0
```

### 2. Install New Package

```bash
peer lifecycle chaincode install niop_v2.tar.gz
```

### 3. Approve with New Sequence

```bash
peer lifecycle chaincode approveformyorg \
  --channelID tolling-channel \
  --name niop \
  --version 2.0 \
  --package-id niop_2.0:def456... \
  --sequence 2 \
  --collections-config collections_config.json
```

### 4. Commit Upgrade

```bash
peer lifecycle chaincode commit \
  --channelID tolling-channel \
  --name niop \
  --version 2.0 \
  --sequence 2 \
  --collections-config collections_config.json \
  --peerAddresses peer0.org1.example.com:7051 \
  --peerAddresses peer0.org2.example.com:7051
```

## Adding New Agencies

When a new agency joins the network:

1. **Update collections_config.json** - Add bilateral collections for the new agency with each existing agency

2. **Upgrade chaincode** - Even if code unchanged, sequence must increment for new collections

3. **Coordinate timing** - All orgs must approve with updated collections config

## Monitoring

### Query Chaincode

```bash
peer chaincode query \
  --channelID tolling-channel \
  --name niop \
  --ctor '{"function":"GetAgency","Args":["TCA"]}'
```

### Invoke Chaincode

```bash
peer chaincode invoke \
  --channelID tolling-channel \
  --name niop \
  --ctor '{"function":"CreateAgency","Args":["{\"agencyID\":\"TCA\",\"name\":\"Transportation Corridor Agencies\",...}"]}' \
  --peerAddresses peer0.org1.example.com:7051 \
  --waitForEvent
```

### Check CouchDB Directly

```bash
# List all documents of a type
curl 'http://localhost:5984/channel_niop/_find' \
  -H 'Content-Type: application/json' \
  -d '{"selector":{"docType":"agency"}}'
```

## Troubleshooting

### Chaincode Container Logs

```bash
docker logs dev-peer0.org1.example.com-niop-1.0
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "collection not defined" | Missing collection in config | Add to collections_config.json, upgrade |
| "index not found" | CouchDB index missing | Check META-INF path, redeploy |
| "endorsement failure" | Policy not satisfied | Check org endorsements |
