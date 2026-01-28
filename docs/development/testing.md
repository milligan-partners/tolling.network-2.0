# Testing Guide

This document describes testing practices for the Tolling Network chaincode.

## Test Structure

Tests are co-located with the code they test:

```
chaincode/niop/
├── models/
│   ├── tag.go
│   ├── tag_test.go          # Model tests
│   ├── charge.go
│   └── charge_test.go
├── tag_contract.go
├── tag_contract_test.go     # Contract tests
├── mock_stub_test.go        # Shared test utilities
└── ...
```

## Running Tests

### All Tests

```bash
cd chaincode/niop
go test ./...
```

### Verbose Output

```bash
go test ./... -v
```

### Specific Package

```bash
go test ./models -v
```

### Specific Test

```bash
go test -run TestCreateCharge -v
```

### With Coverage

```bash
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html
```

## Test Patterns

### Model Tests

Model tests verify:
- Validation logic
- Status transition rules
- Key generation
- Timestamp handling

Example structure:
```go
func TestTag_Validate(t *testing.T) {
    t.Run("accepts valid tag", func(t *testing.T) {
        tag := validTag()
        err := tag.Validate()
        require.NoError(t, err)
    })

    t.Run("rejects missing serial number", func(t *testing.T) {
        tag := validTag()
        tag.TagSerialNumber = ""
        err := tag.Validate()
        require.Error(t, err)
        assert.Contains(t, err.Error(), "tagSerialNumber")
    })
}
```

### Contract Tests

Contract tests verify:
- CRUD operations
- Business rule enforcement
- State persistence

The enhanced mock context supports:
- World state operations
- Private data collections
- Rich queries (CouchDB selectors)

Example:
```go
func TestCreateCharge(t *testing.T) {
    contract := &ChargeContract{}

    t.Run("creates valid charge", func(t *testing.T) {
        ctx := newMockContext()
        charge := validCharge()
        chargeJSON, _ := json.Marshal(charge)

        err := contract.CreateCharge(ctx, string(chargeJSON))
        require.NoError(t, err)

        // Verify private data was written
        bytes, err := ctx.stub.GetPrivateData("charges_ORG1_ORG2", "CHARGE_CHG-001")
        require.NoError(t, err)
        require.NotNil(t, bytes)
    })
}
```

## Mock Infrastructure

### Enhanced Mock Stub

`mock_stub_test.go` provides `enhancedMockStub` which extends Fabric's `shimtest.MockStub`:

```go
type enhancedMockStub struct {
    *shimtest.MockStub
    privateData map[string]map[string][]byte
}
```

Supports:
- `GetState` / `PutState` - World state
- `GetPrivateData` / `PutPrivateData` - Private collections
- `GetStateByRange` - Key range queries
- `GetQueryResult` - CouchDB rich queries
- `GetPrivateDataQueryResult` - Private data rich queries

### Mock Context

```go
ctx := newMockContext()           // Returns *enhancedMockContext
ctx := newEnhancedMockContext()   // Same thing (explicit name)
```

Access the stub directly for assertions:
```go
bytes, err := ctx.stub.GetState("KEY")
bytes, err := ctx.stub.GetPrivateData("collection", "KEY")
```

## Testing Rich Queries

The mock stub parses CouchDB selectors and filters results:

```go
t.Run("returns tags by agency", func(t *testing.T) {
    ctx := newEnhancedMockContext()

    // Create test data
    tag := validTag()
    tagJSON, _ := json.Marshal(tag)
    _ = contract.CreateTag(ctx, string(tagJSON))

    // Query uses rich query internally
    result, err := contract.GetTagsByAgency(ctx, "TCA")
    require.NoError(t, err)
    assert.Len(t, result, 1)
})
```

Supported selector patterns:
```json
{"selector": {"docType": "tag", "tagAgencyID": "TCA"}}
```

## Test Helpers

### Valid Entity Factories

Each test file defines a factory function returning valid test data:

```go
func validTag() *models.Tag {
    return &models.Tag{
        TagSerialNumber: "TCA.000000001",
        TagAgencyID:     "TCA",
        HomeAgencyID:    "BATA",
        Status:          "valid",
        // ... other required fields
    }
}
```

Modify the returned object for specific test scenarios:
```go
tag := validTag()
tag.Status = "invalid"  // Test invalid status handling
```

## Best Practices

1. **Use table-driven tests** for exhaustive validation:
   ```go
   tests := []struct {
       name    string
       status  string
       wantErr bool
   }{
       {"valid status", "active", false},
       {"invalid status", "bad", true},
   }
   for _, tt := range tests {
       t.Run(tt.name, func(t *testing.T) { ... })
   }
   ```

2. **Test both success and failure paths**

3. **Verify error messages contain useful context**:
   ```go
   assert.Contains(t, err.Error(), "tagSerialNumber")
   ```

4. **Use `require` for fatal assertions, `assert` for non-fatal**:
   ```go
   require.NoError(t, err)  // Stop test if this fails
   assert.Equal(t, expected, actual)  // Continue even if fails
   ```

5. **Keep test data realistic** - use actual agency IDs, valid formats

## Debugging Test Failures

### Print State

```go
bytes, _ := ctx.stub.GetState("KEY")
t.Logf("State: %s", string(bytes))
```

### Run Single Test with Verbose

```bash
go test -run TestCreateCharge/creates_valid_charge -v
```

### Check Mock State

```go
// Dump all keys
for element := ctx.stub.Keys.Front(); element != nil; element = element.Next() {
    t.Logf("Key: %s", element.Value)
}
```
