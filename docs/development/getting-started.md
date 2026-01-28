# Getting Started

This guide helps developers set up their environment and understand the codebase structure.

## Prerequisites

- **Go 1.21+**: The chaincode is written in Go
- **Docker**: Required for running the Fabric network locally
- **Hyperledger Fabric 2.5+**: Chaincode targets Fabric 2.x

## Repository Structure

```
tolling-network-2.0/
├── chaincode/
│   └── niop/                    # NIOP chaincode package
│       ├── models/              # Data models (Tag, Charge, etc.)
│       ├── META-INF/
│       │   └── statedb/
│       │       └── couchdb/
│       │           └── indexes/ # CouchDB index definitions
│       ├── *_contract.go        # Smart contract implementations
│       └── *_test.go            # Unit tests
├── docs/
│   ├── architecture/
│   │   ├── design.md            # Technical design document
│   │   └── decisions/           # Architecture Decision Records
│   ├── domain/
│   │   ├── glossary.md          # Terminology definitions
│   │   └── workflows.md         # Business process flows
│   └── development/             # Developer guides
└── README.md
```

## Building

```bash
cd chaincode/niop
go build ./...
```

## Running Tests

```bash
cd chaincode/niop
go test ./... -v
```

### Test Coverage

```bash
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

## Key Concepts

### Models

Located in `chaincode/niop/models/`, each model represents a domain entity:

| Model | Description | Storage |
|-------|-------------|---------|
| Agency | Network participant | World state |
| Tag | Transponder/account | World state |
| Charge | Toll transaction | Private collection |
| Reconciliation | Posting confirmation | World state |
| Settlement | Financial summary | Private collection |
| Correction | Charge adjustment | Private collection |
| Acknowledgement | Batch receipt | World state |

### Contracts

Located in `chaincode/niop/`, each contract handles operations for a model:

- `AgencyContract`: CRUD for agency registration
- `TagContract`: Tag lifecycle management
- `ChargeContract`: Charge creation and status updates
- `ReconciliationContract`: Reconciliation records
- `SettlementContract`: Settlement lifecycle
- `CorrectionContract`: Charge corrections
- `AcknowledgementContract`: Batch acknowledgements

### Private Data Collections

Bilateral data (charges, settlements, corrections) uses private collections:

```
charges_{smaller_agency}_{larger_agency}
```

See [ADR-001](../architecture/decisions/001-bilateral-private-collections.md) for details.

## Common Tasks

### Adding a New Field to a Model

1. Add the field to the struct in `models/<entity>.go`
2. Update `Validate()` if the field has validation rules
3. Update tests in `models/<entity>_test.go`
4. If queryable, add a CouchDB index in `META-INF/statedb/couchdb/indexes/`

### Adding a New Query Method

1. Add the method to the appropriate contract
2. If using rich queries, ensure a CouchDB index exists
3. Add tests using `newEnhancedMockContext()` for rich query support

### Adding a New Model

1. Create `models/<entity>.go` with struct and methods
2. Create `models/<entity>_test.go`
3. Create `<entity>_contract.go` with CRUD operations
4. Create `<entity>_contract_test.go`
5. Add relevant CouchDB indexes

## Architecture Decisions

Key design decisions are documented as ADRs in `docs/architecture/decisions/`:

- [ADR-001: Bilateral Private Collections](../architecture/decisions/001-bilateral-private-collections.md)
- [ADR-002: CouchDB Rich Queries](../architecture/decisions/002-couchdb-rich-queries.md)
- [ADR-003: State Machine Validation](../architecture/decisions/003-state-machine-validation.md)
- [ADR-004: JSON API Pattern](../architecture/decisions/004-json-api-pattern.md)

## Further Reading

- [Technical Design](../architecture/design.md)
- [Domain Glossary](../domain/glossary.md)
- [Workflow Diagrams](../domain/workflows.md)
