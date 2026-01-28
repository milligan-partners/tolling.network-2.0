# Contributing to Tolling.Network

## Prerequisites

- Docker and Docker Compose
- Go 1.22+
- Node.js 20 LTS (see `.nvmrc`)
- Python 3.8+ (for data generation tools)
- An editor that supports [EditorConfig](https://editorconfig.org/)

## Getting Started

```bash
# Start the local Fabric network
make docker-up

# Run all tests
make test

# Run all linters
make lint

# See all available targets
make help
```

## Development Workflow

1. Create a feature branch from `main`
2. Make your changes
3. Write tests for any new or modified code
4. Run tests: `make test`
5. Run linting: `make lint`
6. Commit using conventional commit format
7. Submit a pull request

## Branch Naming

| Prefix | Use |
|---|---|
| `feature/` | New features |
| `fix/` | Bug fixes |
| `docs/` | Documentation updates |
| `infra/` | Infrastructure changes |
| `security/` | Security fixes or hardening |
| `refactor/` | Code restructuring without behavior change |

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add tag validation endpoint
fix: resolve NIOP reconciliation data parsing
docs: update local dev setup guide
chore: update Fabric SDK to 1.10.0
security: enable mutual TLS on peer connections
refactor: extract charge validation into shared package
```

- Use imperative mood ("add", not "added" or "adds")
- Keep the first line under 72 characters
- Add a body for non-trivial changes explaining **why**, not just what
- Reference issue numbers where applicable: `fix: resolve duplicate charge bug (#42)`

## Code Standards

### Go Chaincode

- Follow standard Go conventions (`gofmt`, `go vet`)
- One chaincode package per protocol domain (`niop/`, `ctoc/`)
- Shared utilities go in `chaincode/shared/`
- Models go in `models/` subdirectory within each chaincode package
- CouchDB indexes go in `META-INF/statedb/couchdb/indexes/`
- Use the Hyperledger Fabric `contractapi` package
- Every exported function must have a test

```bash
# Run chaincode tests
make chaincode-test

# Lint chaincode
make chaincode-lint
```

### TypeScript API

- NestJS module structure: one module per domain
- Fabric Gateway client lives in `src/fabric/`
- Use strict TypeScript (`strict: true` in tsconfig)
- 2-space indentation (enforced by `.editorconfig`)

```bash
# Install dependencies
make api-install

# Run API in dev mode
make api-dev

# Run API tests
make api-test

# Lint API code
make api-lint
```

### General

- UTF-8 encoding, LF line endings (enforced by `.editorconfig`)
- Trim trailing whitespace (except in Markdown)
- Every file ends with a newline
- Indentation by file type: tabs for Go and Makefiles, 2 spaces for TypeScript/JSON/YAML/Terraform

## Security Requirements

This project handles toll interoperability data for government agencies. Security is not optional.

### Never commit

- Credentials, passwords, API keys, or tokens (use environment variables)
- Private keys, certificates, or wallet files (covered by `.gitignore`)
- PII (personally identifiable information) in any form
- Terraform variable files containing secrets (`*.tfvars`)
- Industry specification documents (proprietary, covered by `.gitignore`)

### Code security checklist

- [ ] No hardcoded credentials — use environment variables or GCP Secret Manager
- [ ] TLS enabled for all network communication (mutual TLS preferred)
- [ ] Input validation on all chaincode functions that accept external data
- [ ] Private data collections use `requiredPeerCount >= 1` (2 for production)
- [ ] No Docker socket mounts — use Fabric's external chaincode launcher
- [ ] K8s manifests include `securityContext`, `runAsNonRoot`, resource limits
- [ ] Shell scripts use `set -euo pipefail` and quote all variables
- [ ] CouchDB queries use authenticated connections, never plaintext HTTP
- [ ] Log levels set to INFO or above (no DEBUG in staging/production)

### Encryption

All sensitive data on the ledger must be encrypted using real encryption (`chaincode/shared/encryption.go`). Base64 encoding is **not** encryption. The legacy codebase had no-op encryption stubs throughout — do not repeat this pattern.

## Testing

All code must include tests before merging. The legacy codebase had zero test coverage across 7 repositories. We do not carry that forward.

### What to test

- **Chaincode**: Every exported function, every validation path, every error case. Use Fabric's mock stub for unit tests.
- **API**: Endpoint integration tests, service unit tests, Fabric Gateway interaction tests.
- **Infrastructure**: Validate configs with `docker compose config` and `terraform validate` before committing.

### Running tests

```bash
# All tests
make test

# Chaincode only
make chaincode-test

# API only
make api-test
```

## Project Structure

```
chaincode/          Go smart contracts
  niop/             National interop chaincode
  ctoc/             California/Western region chaincode
  shared/           Shared Go utilities (encryption, lookups)
  testdata/         Test fixtures
api/                NestJS REST API (TypeScript)
infrastructure/
  docker/           Local dev environment (docker-compose)
  terraform/        GKE cluster provisioning
  bevel/            Hyperledger Bevel configuration
  k8s/              Kubernetes manifests
network-config/     Fabric configtx, crypto-config, collection configs
tools/              Data generation, CouchDB queries, admin scripts
docs/
  architecture/     Mermaid diagrams (.mmd)
  onboarding/       Developer setup guides
  protocols/        NIOP/CTOC reference
  api/              Contract schema
```

## Pull Requests

- One logical change per PR
- Include a description of **what** changed and **why**
- Reference related issues
- All tests must pass
- All linting must pass
- At least one reviewer approval before merging
- Squash-merge to keep `main` history clean

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

Copyright 2016-2026 Milligan Partners LLC.
