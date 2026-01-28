# Contributing to Tolling.Network

## Development Workflow

1. Create a feature branch from `main`
2. Make your changes
3. Run tests: `make test`
4. Run linting: `make lint`
5. Submit a pull request

## Branch Naming

- `feature/` — New features
- `fix/` — Bug fixes
- `docs/` — Documentation updates
- `infra/` — Infrastructure changes

## Commit Messages

Use conventional commit format:

```
feat: add tag validation endpoint
fix: resolve NIOP reconciliation data parsing
docs: update local dev setup guide
chore: update Fabric SDK to 1.10.0
```

## Code Standards

- **Go chaincode**: Follow standard Go conventions, run `go vet` and `golint`
- **TypeScript API**: Follow the project ESLint config, use strict TypeScript
- **All code**: Must include tests before merging
