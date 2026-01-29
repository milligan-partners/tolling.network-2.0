# Getting Started

This guide covers local development setup for Tolling.Network.

## Prerequisites

- **Docker Desktop** 29.x+ (or Docker Engine with API v1.44+)
- **Go 1.24+**
- **Node.js 20 LTS** (see `.nvmrc`)
- **Hyperledger Fabric binaries** 2.5.x (cryptogen, configtxgen, peer CLI)
- An editor with [EditorConfig](https://editorconfig.org/) support

### Installing Fabric Binaries

```bash
# Download Fabric 2.5.x binaries
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.4 1.5.7

# Add to PATH
export PATH=$PATH:/path/to/fabric-samples/bin
```

## Quick Start

```bash
# Clone the repository
git clone https://github.com/milligan-partners/tolling-network-2.0.git
cd tolling-network-2.0

# Initialize the Fabric network (generates crypto material and genesis block)
make network-init

# Start the local Fabric network (orderers, peers, CouchDB, CAs)
make docker-up

# Create channel and join all peers
make channel-create

# Deploy chaincode using Chaincode as a Service (ccaas)
make ccaas-deploy

# Run chaincode unit tests
make chaincode-test

# Run integration tests (requires deployed chaincode)
make integration-test

# See all available commands
make help
```

## Development Workflow

We follow a **Research → Plan → Implement → Test → Document** workflow. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for details.

## Common Commands

| Command | Description |
|---------|-------------|
| `make network-init` | Generate crypto material and channel artifacts |
| `make docker-up` | Start local Fabric network |
| `make docker-down` | Stop local Fabric network |
| `make docker-reset` | Stop, remove volumes, and restart |
| `make docker-logs` | Tail logs from all containers |
| `make docker-status` | Show container status |
| `make channel-create` | Create channel and join peers |
| `make ccaas-deploy` | Deploy chaincode using Chaincode as a Service (recommended) |
| `make chaincode-deploy` | Deploy chaincode (traditional method) |
| `make chaincode-test` | Run Go chaincode tests |
| `make chaincode-lint` | Lint Go chaincode |
| `make integration-test` | Run integration tests (requires running network) |
| `make network-down` | Full teardown |

## Chaincode as a Service (ccaas)

The local development environment uses **Chaincode as a Service (ccaas)** for deploying chaincode. This approach:

- Runs chaincode as an external gRPC server
- Eliminates Docker socket dependency (required for Docker Desktop 29.x+ compatibility)
- Matches production deployment patterns
- Enables easier debugging (chaincode logs visible via `docker logs niop-chaincode`)

The ccaas deployment:
1. Builds a Docker image for the chaincode (`niop-chaincode:1.0`)
2. Creates a ccaas package with connection info
3. Installs the package on all peers
4. Starts the chaincode container
5. Approves and commits the chaincode definition

## Project Structure

```
tolling-network-2.0/
├── chaincode/           # Go smart contracts
│   ├── niop/            # National interop chaincode
│   │   ├── ccaas/       # Chaincode as a Service files (Dockerfile, connection.json)
│   │   ├── cmd/         # Chaincode main entry point
│   │   └── models/      # Domain entity structs
│   ├── ctoc/            # California interop chaincode
│   ├── integration/     # Integration tests (Fabric Gateway SDK)
│   └── shared/          # Shared utilities and test helpers
├── api/                 # NestJS REST API (scaffold)
├── config/              # Fabric configuration files (core.yaml, orderer.yaml)
├── infrastructure/
│   └── docker/          # Local dev docker-compose
├── network-config/      # Fabric crypto-config, configtx, collections
├── scripts/             # Network lifecycle scripts
│   ├── network-init.sh  # Generate crypto and channel artifacts
│   ├── create-channel.sh # Create channel and join peers
│   └── deploy-ccaas.sh  # Chaincode as a Service deployment
└── docs/                # Documentation
```

## Troubleshooting

### Docker API Version Error

If you see an error like "client version 1.25 is too old. Minimum supported API version is 1.44":
- This affects Docker Desktop 29.x+ with traditional chaincode deployment
- Use `make ccaas-deploy` instead of `make chaincode-deploy`
- The ccaas approach doesn't require Docker socket access from peers

### Channel Creation Fails

If channel creation fails with "orderer unreachable":
- Ensure all orderers are running: `docker ps | grep orderer`
- Check orderer logs: `docker logs orderer1.orderer.tolling.network`
- Verify the Raft cluster has elected a leader

### Chaincode Invocation Fails with Endorsement Policy Error

If you see "endorsement policy failure" with message about "3 of 4 sub-policies":
- The default endorsement policy requires majority (3 of 4) organization endorsement
- For manual testing via CLI, use `--peerAddresses` to specify multiple peers
- For integration tests, the Fabric Gateway SDK may need configuration for multi-peer endorsement

## Next Steps

- Read the [Architecture & Design](../architecture/design.md) document
- Review the [Domain Glossary](../domain/glossary.md) for industry terminology
- Check [Testing](testing.md) for test conventions
