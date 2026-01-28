# Contract Design Methodology

How to design, implement, and test a new chaincode contract for Tolling.Network 2.0.

This document is a thinking framework. It walks through the decisions you need to make — in order — when adding a new business rule, entity, or transaction type to the ledger. Follow it sequentially. Each section builds on the previous one.

## Prerequisites

Read these first:

- `CLAUDE.md` — Architecture decisions, domain concepts, tech stack
- `docs/onboarding/testing.md` — Test conventions and helpers
- `CONTRIBUTING.md` — Code standards, security checklist
- `docs/architecture/*.mmd` — Data model, privacy model, transaction lifecycle

Understand how the existing 7 entities work by reading `chaincode/niop/models/`. Every new contract follows the same structural patterns established there.

## Step 1: Define the Business Rule

Before writing any code, answer these questions in plain language:

### 1a. What real-world event triggers this?

Every contract function maps to something that happens in the physical world or in an agency's back-office system. Name it concretely.

Examples from existing contracts:
- "A vehicle drives through a toll gantry" → CreateCharge
- "A home agency posts a charge to a customer's account" → CreateReconciliation
- "Two agencies agree on a monthly financial total" → CreateSettlement

### 1b. Who are the participants?

Identify the Fabric organizations involved. In toll interop, most transactions are bilateral (two agencies). Some are unilateral (one agency publishes data) or multilateral (consortium-wide).

| Pattern | Example | Storage |
|---|---|---|
| **Unilateral** | Agency publishes its tag list | Private data: `tvl_{agency}` |
| **Bilateral** | Away agency charges home agency | Private data: `charges_{A}_{B}` |
| **Multilateral** | Consortium adopts a new rule version | World state (public to channel) |

### 1c. What data does it carry?

List every field. For each field, decide:
- **Required or optional?** Required fields fail validation if missing.
- **Enum or free-form?** Enums get a `ValidXxx` slice and validation. Free-form fields get length/format checks if needed.
- **Sensitive?** Anything that could identify a customer is PII and must not go on the ledger. Period.

### 1d. What protocol does it belong to?

Tolling.Network supports multiple industry protocols. Your contract must know which protocol's rules apply:

| Protocol | Scope | Chaincode Package |
|---|---|---|
| NIOP ICD | National interop | `chaincode/niop/` |
| IAG Inter-CSC | E-ZPass consortium | `chaincode/niop/` (shared national rules) |
| CTOC | California/Western | `chaincode/ctoc/` |
| Native | Tolling.Network-specific extensions | Whichever package owns the entity |

If the rule is protocol-specific, it goes in that protocol's chaincode package. If it's cross-protocol, consider whether it belongs in `chaincode/shared/`.

## Step 2: Design the Data Model

### 2a. Define the struct

Create a Go struct in the appropriate `models/` directory. Follow the established pattern:

```go
// chaincode/niop/models/yourmodel.go
package models

type YourEntity struct {
    // Identity fields — what makes this unique
    EntityID string `json:"entityID"`

    // Reference fields — links to other entities
    RelatedChargeID string `json:"relatedChargeID"`

    // Domain fields — the business data
    Amount    float64 `json:"amount"`
    Reason    string  `json:"reason"`

    // Status field — if lifecycle applies
    Status string `json:"status"`

    // Timestamps
    CreatedAt string `json:"createdAt"`
    UpdatedAt string `json:"updatedAt,omitempty"`
}
```

Design rules:
- **JSON tags on every field.** Use camelCase for JSON, matching the struct field names.
- **Use `omitempty` for truly optional fields.** Don't use it for fields that are required.
- **No Fabric SDK imports at the model layer.** Models are pure Go. This keeps them testable without mocks.
- **Nested structs are fine** (see `Tag` with `DiscountPlan` and `Plate`). Define them in the same file.

### 2b. Define the ledger key

Every entity needs a deterministic, unique key. Implement `Key()`:

```go
func (e *YourEntity) Key() string {
    return "YOURENTITY_" + e.EntityID
}
```

Key design rules:
- **Prefix with the entity type in uppercase.** This prevents collisions across entity types and makes CouchDB queries cleaner.
- **Use underscores as separators.**
- **Composite keys** (multiple parts) use underscore separation: `CORRECTION_{chargeID}_{seqNo}`
- **Zero-pad numeric components** for sort order: `fmt.Sprintf("CORRECTION_%s_%03d", chargeID, seqNo)`
- **Keys must be deterministic.** Given the same input, `Key()` must always return the same string. Never include timestamps or random values.

### 2c. Decide on storage location

This is the most important architectural decision. Refer to the privacy model (`docs/architecture/data-privacy.mmd`):

| Storage | When to use | Key consideration |
|---|---|---|
| **World state** | Non-sensitive reference data visible to all channel members | Agency registry, acknowledgements, protocol versions |
| **Private data (unilateral)** | Data owned by one org, shared with selected others | Tag validation lists: `tvl_{homeAgency}` |
| **Private data (bilateral)** | Sensitive transaction data between exactly two orgs | Charges, corrections, reconciliations, settlements |

If bilateral, implement `CollectionName()`:

```go
func (e *YourEntity) CollectionName() string {
    a, b := e.AgencyA, e.AgencyB
    if a > b {
        a, b = b, a
    }
    return "yourprefix_" + a + "_" + b
}
```

The alphabetical sort ensures both agencies resolve to the same collection name regardless of who initiates the transaction. This is a hard requirement — bilateral collections must be symmetric.

### 2d. Define validation

Implement `Validate()` returning the first error found (fail-fast):

```go
func (e *YourEntity) Validate() error {
    // 1. Required fields
    if e.EntityID == "" {
        return fmt.Errorf("entityID is required")
    }

    // 2. Enum validation
    if !contains(ValidReasons, e.Reason) {
        return fmt.Errorf("invalid reason: %s", e.Reason)
    }

    // 3. Range/format checks
    if e.Amount < 0 {
        return fmt.Errorf("amount must be non-negative")
    }

    // 4. Cross-field rules
    if e.AgencyA == e.AgencyB {
        return fmt.Errorf("agencies must be different")
    }

    // 5. Conditional requirements
    if e.Type == "special" && e.SpecialField == "" {
        return fmt.Errorf("specialField is required when type is special")
    }

    return nil
}
```

Validation ordering matters. Check in this order:
1. Required fields (fastest to check, most common error)
2. Enum values (invalid data)
3. Numeric ranges and format constraints
4. Cross-field business rules
5. Conditional requirements

### 2e. Define status lifecycle (if applicable)

Not every entity has a status. But if yours does, define:

1. The valid statuses:
```go
var ValidYourEntityStatuses = []string{"draft", "active", "closed"}
```

2. The allowed transitions:
```go
var allowedYourEntityTransitions = map[string][]string{
    "draft":  {"active"},
    "active": {"closed"},
}
```

3. The transition validator:
```go
func (e *YourEntity) ValidateStatusTransition(newStatus string) error {
    allowed, exists := allowedYourEntityTransitions[e.Status]
    if !exists {
        return fmt.Errorf("unknown current status: %s", e.Status)
    }
    if !contains(allowed, newStatus) {
        return fmt.Errorf("cannot transition from %s to %s", e.Status, newStatus)
    }
    return nil
}
```

Ask yourself: **Is every transition reversible? Should it be?** In toll interop, most lifecycle flows are forward-only (a charge moves from pending to posted to settled). But disputes and corrections create backward paths. Map the full state diagram before coding.

## Step 3: Write the Model Tests

Write tests before or alongside the model code. Tests go in the same package, same directory.

### 3a. Create a test factory

Each test file defines its own `validYourEntity()` factory that returns a minimally valid instance:

```go
func validYourEntity() *YourEntity {
    return &YourEntity{
        EntityID: "TEST-001",
        Reason:   "C",
        Amount:   10.00,
        Status:   "draft",
    }
}
```

Why not use `testutil.SampleXxx()`? Those return `map[string]interface{}` for contract-level tests. Model tests work directly with typed structs.

### 3b. Test categories

Every model needs these test categories:

1. **Happy path** — `TestValidate_ValidEntity`: A fully valid entity passes validation.
2. **Required fields** — One subtest per required field, setting it to `""` (or zero value) and asserting the specific error message.
3. **Invalid enums** — One subtest per enum field with an invalid value.
4. **Range checks** — Negative amounts, out-of-range sequence numbers, etc.
5. **Cross-field rules** — Same agency on both sides, conditional requirements.
6. **Key generation** — Verify `Key()` returns the expected string.
7. **Status transitions** (if applicable) — Test every valid transition and at least one invalid transition per status.
8. **Collection naming** (if bilateral) — Verify symmetry: `CollectionName()` returns the same value regardless of agency order.

Use table-driven tests for categories with many cases (required fields, enum validation, status transitions).

## Step 4: Design the Contract Functions

Contract functions are the Fabric `contractapi` entry points that wire models to the ledger. They live in the chaincode package (not in `models/`).

### 4a. Identify the operations

Every entity needs at minimum:
- **Create** — Write a new instance to the ledger
- **Get** — Read an instance by key

Most entities also need:
- **Update** — Modify specific fields (usually status)
- **Query** — Search by non-key fields (requires CouchDB indexes)

Some entities need:
- **List** — Get all instances matching criteria
- **Delete** — Remove from state (rare in toll interop — most data is retained)

### 4b. Map operations to Fabric primitives

| Operation | World State | Private Data |
|---|---|---|
| Create | `PutState(key, value)` | `PutPrivateData(collection, key, value)` |
| Get | `GetState(key)` | `GetPrivateData(collection, key)` |
| Update | `GetState` + modify + `PutState` | `GetPrivateData` + modify + `PutPrivateData` |
| Query | `GetQueryResult(query)` | `GetPrivateDataQueryResult(collection, query)` |
| Delete | `DelState(key)` | `DelPrivateData(collection, key)` |

### 4c. Define the contract struct

```go
// chaincode/niop/yourentity_contract.go
package niop

import (
    "encoding/json"
    "fmt"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
    "github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
)

// YourEntityContract handles YourEntity transactions
type YourEntityContract struct {
    contractapi.Contract
}
```

One contract struct per entity. This keeps files focused and testable.

### 4d. Implement contract functions

Follow this pattern for every Create function:

```go
func (c *YourEntityContract) CreateYourEntity(
    ctx contractapi.TransactionContextInterface,
    entityJSON string,
) error {
    // 1. Deserialize input
    var entity models.YourEntity
    if err := json.Unmarshal([]byte(entityJSON), &entity); err != nil {
        return fmt.Errorf("failed to parse entity: %w", err)
    }

    // 2. Validate
    if err := entity.Validate(); err != nil {
        return fmt.Errorf("validation failed: %w", err)
    }

    // 3. Check for duplicates
    existing, err := ctx.GetStub().GetState(entity.Key())
    if err != nil {
        return fmt.Errorf("failed to read state: %w", err)
    }
    if existing != nil {
        return fmt.Errorf("entity %s already exists", entity.EntityID)
    }

    // 4. Set metadata
    entity.SetCreatedAt()

    // 5. Marshal and store
    bytes, err := json.Marshal(entity)
    if err != nil {
        return fmt.Errorf("failed to marshal entity: %w", err)
    }

    return ctx.GetStub().PutState(entity.Key(), bytes)
}
```

For private data entities, replace `GetState`/`PutState` with `GetPrivateData`/`PutPrivateData` using `entity.CollectionName()`.

Follow this pattern for Get functions:

```go
func (c *YourEntityContract) GetYourEntity(
    ctx contractapi.TransactionContextInterface,
    entityID string,
) (*models.YourEntity, error) {
    key := "YOURENTITY_" + entityID
    bytes, err := ctx.GetStub().GetState(key)
    if err != nil {
        return nil, fmt.Errorf("failed to read state: %w", err)
    }
    if bytes == nil {
        return nil, fmt.Errorf("entity %s not found", entityID)
    }

    var entity models.YourEntity
    if err := json.Unmarshal(bytes, &entity); err != nil {
        return nil, fmt.Errorf("failed to parse entity: %w", err)
    }

    return &entity, nil
}
```

Follow this pattern for status update functions:

```go
func (c *YourEntityContract) UpdateYourEntityStatus(
    ctx contractapi.TransactionContextInterface,
    entityID string,
    newStatus string,
) error {
    // 1. Retrieve existing
    entity, err := c.GetYourEntity(ctx, entityID)
    if err != nil {
        return err
    }

    // 2. Validate transition
    if err := entity.ValidateStatusTransition(newStatus); err != nil {
        return fmt.Errorf("invalid status transition: %w", err)
    }

    // 3. Apply change
    entity.Status = newStatus
    entity.TouchUpdatedAt()

    // 4. Store
    bytes, err := json.Marshal(entity)
    if err != nil {
        return fmt.Errorf("failed to marshal entity: %w", err)
    }

    return ctx.GetStub().PutState(entity.Key(), bytes)
}
```

### 4e. Register the contract

In `main.go`, register all contract structs with the chaincode:

```go
chaincode, err := contractapi.NewChaincode(
    &AgencyContract{},
    &TagContract{},
    &ChargeContract{},
    &YourEntityContract{},  // add yours here
)
```

Each contract's functions are namespaced by the struct name. A function `CreateYourEntity` on `YourEntityContract` is invoked as `YourEntityContract:CreateYourEntity` from the client SDK.

## Step 5: Write Contract Tests

Contract tests use `shimtest.MockStub` to simulate Fabric without running a network.

### 5a. Test structure

```go
// chaincode/niop/yourentity_contract_test.go
package niop

import (
    "testing"
    "github.com/milligan-partners/tolling.network-2.0/chaincode/shared/testutil"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestCreateYourEntity(t *testing.T) {
    stub := testutil.NewMockStub("niop")

    t.Run("creates valid entity", func(t *testing.T) {
        // Arrange
        input := testutil.MustJSON(testutil.SampleYourEntity())

        // Act
        testutil.MockTransactionContext(stub, "tx1")
        response := stub.MockInvoke("tx1", [][]byte{
            []byte("YourEntityContract:CreateYourEntity"),
            input,
        })

        // Assert
        assert.Equal(t, int32(200), response.Status)
        testutil.AssertStateExists(t, stub, "YOURENTITY_TEST-001")
    })

    t.Run("rejects duplicate", func(t *testing.T) {
        // Entity from previous subtest still in state
        input := testutil.MustJSON(testutil.SampleYourEntity())

        response := stub.MockInvoke("tx2", [][]byte{
            []byte("YourEntityContract:CreateYourEntity"),
            input,
        })

        assert.NotEqual(t, int32(200), response.Status)
        assert.Contains(t, response.Message, "already exists")
    })
}
```

### 5b. What to test per contract function

**Create:**
- Valid input succeeds
- Duplicate key rejected
- Invalid input returns validation error
- State was actually written (use `AssertStateExists`)
- Stored data matches input (use `GetStateAs` and compare)

**Get:**
- Existing entity returns correctly
- Missing entity returns descriptive error

**Update status:**
- Valid transition succeeds
- Invalid transition returns error
- Status was actually changed in state
- UpdatedAt timestamp was set
- Missing entity returns error

**Private data operations:**
- Data stored in correct collection name
- Bilateral symmetry: both agencies resolve to same collection

## Step 6: Add CouchDB Indexes

If your entity will be queried by non-key fields, add CouchDB indexes.

### 6a. Where indexes go

```
chaincode/niop/META-INF/statedb/couchdb/indexes/
```

### 6b. Index file format

Each index is a JSON file named descriptively:

```json
// indexYourEntityByStatus.json
{
    "index": {
        "fields": ["status"]
    },
    "ddoc": "indexYourEntityByStatusDoc",
    "name": "indexYourEntityByStatus",
    "type": "json"
}
```

### 6c. When to add an index

Add an index if a contract function uses `GetQueryResult()` or `GetPrivateDataQueryResult()` to search by a field. Without an index, CouchDB does a full scan — acceptable in tests, unacceptable in production.

Common index patterns:
- **By status:** Find all entities in a given status
- **By agency:** Find all entities involving a specific agency
- **By date range:** Find entities within a time period
- **Composite:** Find entities by status AND agency (for dashboard views)

## Step 7: Add the SampleXxx Factory

After the model and contract are working, add a map-based factory function to `chaincode/shared/testutil/fixtures.go`:

```go
func SampleYourEntity() map[string]interface{} {
    return map[string]interface{}{
        "entityID": "TEST-001",
        "reason":   "C",
        "amount":   10.00,
        "status":   "draft",
    }
}
```

This is used by contract-level tests (which pass JSON through the Fabric stub) as opposed to model-level tests (which use typed structs directly).

## Step 8: Update Documentation

After implementation is complete:

1. **CLAUDE.md** — Add the entity to the models table, update implementation progress
2. **README.md** — Update status section if this represents a milestone
3. **docs/architecture/*.mmd** — Update diagrams if the entity changes the data model, privacy boundaries, or transaction lifecycle
4. **docs/api/contract-schema.json** — Add the new contract function signatures

## Decision Framework: When NOT to Create a New Contract

Not every business rule needs a new entity or contract function. Before creating something new, check these alternatives:

### Can you extend an existing entity?

If the new rule is a variation of an existing transaction type, add a new enum value rather than a new entity. Example: adding "congestion pricing" as a charge type didn't require a new entity — it's a value in `ValidChargeTypes`.

### Can you add a validation rule to an existing contract?

If the rule constrains existing behavior (e.g., "charges older than 90 days cannot be reconciled"), add the check inside the existing contract function. Don't create a new contract to enforce it.

### Does it belong in chaincode at all?

Chaincode enforces rules that require consensus across organizations. If a rule is internal to one agency (e.g., how an agency calculates late fees for its customers), it belongs in the agency's back-office system, not on the ledger.

**Put it on the ledger if:**
- Multiple agencies must agree on the rule
- The rule affects interoperability transactions
- Violation of the rule should be cryptographically provable
- The rule is defined by a protocol spec (NIOP, IAG, CTOC)

**Keep it off the ledger if:**
- Only one agency cares about the rule
- It involves PII or customer-specific data
- It's an internal business decision (pricing, staffing, customer communication)
- It changes frequently and doesn't need multi-party consensus

### Does it need its own private data collection?

Most new entities can reuse existing bilateral collections. The `charges_{A}_{B}` pattern already covers corrections, reconciliations, and settlements between two agencies. Only create a new collection pattern if the data has different access control requirements (different set of organizations that can see it).

## Checklist

Use this when designing any new contract:

- [ ] Business rule defined in plain language
- [ ] Participants identified (unilateral / bilateral / multilateral)
- [ ] PII check: no customer data on ledger
- [ ] Protocol assignment (NIOP / IAG / CTOC / native)
- [ ] Go struct defined with JSON tags
- [ ] `Key()` method with deterministic, prefixed key
- [ ] Storage decision (world state vs. private data)
- [ ] `CollectionName()` if bilateral (with alphabetical sort)
- [ ] `Validate()` with ordered checks (required → enum → range → cross-field → conditional)
- [ ] Status lifecycle mapped (if applicable)
- [ ] `ValidateStatusTransition()` (if applicable)
- [ ] Timestamps (`SetCreatedAt`, `TouchUpdatedAt`)
- [ ] Model tests written (happy path, required fields, enums, ranges, cross-field, key, transitions, collection symmetry)
- [ ] Contract struct defined (one per entity)
- [ ] Contract functions implemented (Create, Get, Update)
- [ ] Duplicate detection in Create
- [ ] Contract tests written (valid, duplicate, invalid, state verification)
- [ ] `SampleXxx()` factory added to `testutil/fixtures.go`
- [ ] CouchDB indexes added (if queries needed)
- [ ] Documentation updated (CLAUDE.md, README.md, diagrams, schema)
- [ ] `go test ./...` passes
- [ ] Coverage meets targets (models 90%, contracts 85%)
