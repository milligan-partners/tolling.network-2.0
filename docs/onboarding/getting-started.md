# Getting Started

This guide covers local development setup for Tolling.Network.

## Prerequisites

- **Docker** and Docker Compose
- **Go 1.22+**
- **Node.js 20 LTS** (see `.nvmrc`)
- An editor with [EditorConfig](https://editorconfig.org/) support

## Quick Start

```bash
# Clone the repository
git clone https://github.com/milligan-partners/tolling-network-2.0.git
cd tolling-network-2.0

# Initialize the Fabric network (generates crypto material)
make network-init

# Start the local Fabric network
make docker-up

# Run chaincode tests
make chaincode-test

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
| `make chaincode-test` | Run Go chaincode tests |
| `make chaincode-lint` | Lint Go chaincode |
| `make chaincode-deploy` | Deploy chaincode to network |
| `make network-down` | Full teardown |

## Project Structure

```
tolling-network-2.0/
├── chaincode/           # Go smart contracts
│   ├── niop/            # National interop chaincode
│   ├── ctoc/            # California interop chaincode
│   └── shared/          # Shared utilities and test helpers
├── api/                 # NestJS REST API (scaffold)
├── infrastructure/
│   └── docker/          # Local dev docker-compose
├── network-config/      # Fabric configuration
├── scripts/             # Network lifecycle scripts
└── docs/                # Documentation
```

## Next Steps

- Read the [Architecture & Design](../architecture/design.md) document
- Review the [Domain Glossary](../domain/glossary.md) for industry terminology
- Check [Testing](testing.md) for test conventions
- See [Project Roadmap](../roadmap/epics.md) for current status
