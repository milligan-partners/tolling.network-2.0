# Contributing to Tolling.Network

Thank you for your interest in contributing to Tolling.Network. This project aims to modernize US toll interoperability through a shared blockchain ledger, and we welcome contributions from the community.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Pull Requests](#pull-requests)
- [Security](#security)
- [Getting Help](#getting-help)

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

We follow a **Research → Plan → Implement → Test → Document** workflow:

### 1. Research

- Understand the problem or feature requirements
- Review existing code and patterns in the codebase
- Check ADRs in `docs/architecture/decisions/` for relevant prior decisions
- Consult the [glossary](docs/domain/glossary.md) for domain terminology

### 2. Plan

- For significant changes, write a brief plan before coding
- Consider architectural implications — does this need an ADR?
- Identify affected files and potential breaking changes
- Break large work into smaller, reviewable chunks

### 3. Implement

- Create a feature branch from `main`
- Follow [code standards](#code-standards) for your language
- Keep commits focused and atomic
- Use conventional commit format

### 4. Test

- Write tests for any new or modified code
- Run tests: `make test`
- Run linting: `make lint`
- Verify no regressions in existing functionality

### 5. Document

- Update relevant documentation for user-facing changes
- Add/update ADRs for architectural decisions (`docs/architecture/decisions/`)
- Update the glossary if introducing new domain terms (`docs/domain/glossary.md`)
- Update workflow diagrams if process flows change (`docs/domain/workflows.md`)
- Add inline code comments for non-obvious logic

### 6. Submit

- Submit a pull request with clear description
- Reference related issues
- Respond to reviewer feedback
- Squash-merge when approved

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

## Security

This project handles toll interoperability data for government agencies. Security is not optional.

**To report a security vulnerability**, see [SECURITY.md](SECURITY.md). Do not open public issues for security concerns.

### Security Requirements

Never commit:

- Credentials, passwords, API keys, or tokens (use environment variables)
- Private keys, certificates, or wallet files (covered by `.gitignore`)
- PII (personally identifiable information) in any form
- Terraform variable files containing secrets (`*.tfvars`)
- Industry specification documents (proprietary, covered by `.gitignore`)

### Code Security Checklist

Before submitting a PR, verify:

- [ ] No hardcoded credentials — use environment variables or GCP Secret Manager
- [ ] TLS enabled for all network communication (mutual TLS preferred)
- [ ] Input validation on all chaincode functions that accept external data
- [ ] Private data collections use `requiredPeerCount >= 1` (2 for production)
- [ ] No Docker socket mounts — use Fabric's external chaincode launcher
- [ ] K8s manifests include `securityContext`, `runAsNonRoot`, resource limits
- [ ] Shell scripts use `set -euo pipefail` and quote all variables
- [ ] CouchDB queries use authenticated connections, never plaintext HTTP
- [ ] Log levels set to INFO or above (no DEBUG in staging/production)
- [ ] Sensitive ledger data uses real encryption (`chaincode/shared/encryption.go`), not Base64

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

## Pull Requests

- One logical change per PR
- Include a description of **what** changed and **why**
- Reference related issues
- All tests must pass
- All linting must pass
- At least one reviewer approval before merging
- Squash-merge to keep `main` history clean

## Getting Help

- **Documentation**: See [docs/onboarding/](docs/onboarding/) for detailed guides
- **Questions**: Open a [GitHub Discussion](https://github.com/milligan-partners/tolling.network-2.0/discussions)
- **Bugs**: Open an [issue](https://github.com/milligan-partners/tolling.network-2.0/issues)
- **Security**: See [SECURITY.md](SECURITY.md)

## License

By contributing, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).
