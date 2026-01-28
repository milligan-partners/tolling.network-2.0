# Architecture

## Overview

Tolling.Network 2.0 is a Hyperledger Fabric 2.5 blockchain network for toll interoperability between transportation agencies. The system enables secure, private sharing of toll transaction data across agency boundaries.

## Network Topology

- **Fabric version:** 2.5.x LTS
- **Consensus:** Raft (evaluate SmartBFT from Fabric 3.0 for multi-agency trust model)
- **State database:** CouchDB (required for rich queries)
- **Organizations:** Generic org names (Org1, Org2, Org3, etc.) in sample configs; production deployments use actual agency identifiers

## Components

- **Chaincode (Go):** Smart contracts implementing interoperability protocols
- **API (NestJS):** REST API using @hyperledger/fabric-gateway SDK for client interactions
- **Infrastructure:** GKE cluster provisioned with Terraform, Fabric deployed via Hyperledger Bevel

## Architecture Decision Records

See the [adr/](adr/) directory for documented architectural decisions.
