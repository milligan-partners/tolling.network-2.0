# Testing Methodology

## Principles

1. **Every function gets a test.** The legacy codebase had zero tests across 7 repos. We don't repeat that.
2. **Tests live next to code.** Go tests go in the same package as the code they test (`_test.go` suffix). API tests go in `api/test/` mirroring `api/src/` structure.
3. **Test names describe behavior, not implementation.** Name tests after what the function should do, not how it does it.
4. **Fixtures are shared, helpers are shared, mocks are shared.** All reusable test infrastructure lives in `chaincode/shared/testutil/`.
5. **Tests run fast.** Unit tests must not require Docker, a running Fabric network, or external services. Integration tests are separate.

## Test Categories

### Unit Tests

Test individual functions in isolation. Mock all external dependencies (Fabric stub, CouchDB, network).

- **Chaincode:** Test each contract function with `shimtest.MockStub`. Validate input parsing, state read/write, error handling, and return values.
- **API:** Test each service method with mocked Fabric Gateway. Validate request parsing, response formatting, and error mapping.
- **Shared utilities:** Test encryption, key construction, validation helpers.

**Run:** `make test` or `make chaincode-test` / `make api-test`

### Integration Tests

Test chaincode deployed to a local Fabric network via Docker Compose. These verify endorsement policies, private data collections, and multi-org interactions.

**Run:** `make docker-up && make integration-test`

### Fixture Tests

Validate that test data files conform to expected schemas. Catch fixture drift early.

**Run:** Part of `make test`

## Directory Structure

```
chaincode/
  shared/
    testutil/
      mock_stub.go       # MockStub wrappers and state helpers
      fixtures.go         # Fixture loading, sample data factories, domain constants
  testdata/
    account.json          # 999 accounts (pre-generated, committed)
    tags.json             # Generated tag data (run simple_data_gen.py)
    toll_charges.json     # Generated charge data (run simple_data_gen.py)
    niop-samples/         # NIOP ICD XML schemas (XSD)
      3.4-TagValidationList.xml
      4.3-TransactionData.xml
      5.3-CorrectionData.xml
      6.3-ReconciliationData.xml
      7.5-Acknowledgement.xml
    golden/               # Expected output for golden-file tests
  niop/
    models/
      agency.go
      agency_test.go      # Tests next to code
      charge.go
      charge_test.go
    chaincode.go
    chaincode_test.go
  ctoc/
    models/
      ...same pattern...
    chaincode.go
    chaincode_test.go

api/
  src/
    modules/
      transactions/
        transactions.service.ts
        transactions.controller.ts
  test/
    modules/
      transactions/
        transactions.service.spec.ts    # Unit tests mirror src/ structure
        transactions.controller.spec.ts
    fixtures/
      charges.fixture.ts                # TypeScript test factories
      agencies.fixture.ts
    helpers/
      fabric-mock.ts                    # Mock Fabric Gateway for API tests
```

## Go Chaincode Testing

### File Naming

- Source: `charge.go`
- Test: `charge_test.go` (same directory, same package)
- Test functions: `TestCreateCharge`, `TestCreateCharge_InvalidAgency`, `TestCreateCharge_DuplicateID`

### Test Structure

Use the standard Go test pattern. Group related tests with subtests.

```go
func TestCreateCharge(t *testing.T) {
    // One-time setup for the test group
    stub := testutil.NewMockStub("niop")

    t.Run("valid tag-based charge", func(t *testing.T) {
        // Arrange
        charge := testutil.SampleCharge()

        // Act
        result, err := createCharge(stub, charge)

        // Assert
        assert.NoError(t, err)
        assert.Equal(t, "pending", result.Status)
    })

    t.Run("rejects missing away agency", func(t *testing.T) {
        charge := testutil.SampleCharge()
        delete(charge, "awayAgencyID")

        _, err := createCharge(stub, charge)

        assert.Error(t, err)
        assert.Contains(t, err.Error(), "awayAgencyID")
    })

    t.Run("rejects invalid record type", func(t *testing.T) {
        charge := testutil.SampleCharge()
        charge["recordType"] = "XX99"

        _, err := createCharge(stub, charge)

        assert.Error(t, err)
        assert.Contains(t, err.Error(), "record type")
    })
}
```

### Using Test Helpers

The `chaincode/shared/testutil/` package provides:

| Helper | Purpose |
|---|---|
| `NewMockStub(name)` | Create a configured Fabric mock stub |
| `PutState(t, stub, key, value)` | Marshal and store state (fails test on error) |
| `GetStateAs(t, stub, key, &dest)` | Retrieve and unmarshal state |
| `AssertStateExists(t, stub, key)` | Verify a key was written |
| `AssertStateNotExists(t, stub, key)` | Verify a key was not written |
| `LoadFixture(t, filename, &dest)` | Load JSON from `testdata/` |
| `LoadFixtureBytes(t, filename)` | Load raw bytes (XML, etc.) |
| `SampleCharge()` | Factory for a valid Charge |
| `SampleTag()` | Factory for a valid Tag |
| `SampleReconciliation()` | Factory for a valid Reconciliation |
| `SampleCorrection()` | Factory for a valid Correction |
| `MustJSON(value)` | Marshal to JSON, panic on error |

### What to Test Per Entity

#### Agency
- Create with all required fields
- Reject missing agencyID
- Reject invalid role
- Reject invalid connectivityMode
- Query by consortium membership
- Update status (active -> suspended)

#### Tag
- Create with valid account reference
- Update status transitions (valid -> invalid, valid -> stolen)
- Reject invalid status values
- Tag lookup by serial number
- TVL batch operations (bulk vs. delta indicator)

#### Charge
- Create tag-based charge (TB01)
- Create video/plate-based charge (VB01)
- Reject duplicate chargeID
- Reject charge with unknown home agency
- Reject charge with invalid record type
- Status transitions (pending -> posted -> settled)
- Verify private data stored in correct collection

#### Correction
- Create correction for existing charge
- Increment correction sequence number
- Reject correction for nonexistent charge
- Validate correction reason codes (C/I/L/T/O)
- Verify record type suffix (TB01 -> TB01A)

#### Reconciliation
- Post charge successfully (disposition P)
- Reject with disposition codes (D, I, N, S, T, C, O)
- Verify posted amount can differ from charge amount
- Reject reconciliation for already-reconciled charge

#### Acknowledgement
- Generate ack for TVL submission (return code 00)
- Generate error ack (return codes 01-13)
- Reject invalid submission type

#### Settlement
- Calculate net amount for a period
- Handle corrections in settlement calculation
- Status transitions (draft -> submitted -> accepted -> paid)
- Verify bilateral scoping (only charges between payor and payee)

### Table-Driven Tests

For validation logic with many cases, use table-driven tests:

```go
func TestValidateRecordType(t *testing.T) {
    tests := []struct {
        name       string
        recordType string
        wantErr    bool
    }{
        {"valid TB01", "TB01", false},
        {"valid TC01", "TC01", false},
        {"valid TC02", "TC02", false},
        {"valid VB01", "VB01", false},
        {"valid VC01", "VC01", false},
        {"valid VC02", "VC02", false},
        {"invalid type", "XX99", true},
        {"empty string", "", true},
        {"correction suffix alone", "A", true},
        {"lowercase", "tb01", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := validateRecordType(tt.recordType)
            if tt.wantErr {
                assert.Error(t, err)
            } else {
                assert.NoError(t, err)
            }
        })
    }
}
```

### Golden File Tests

For complex outputs (JSON responses, serialized state), compare against committed golden files in `chaincode/testdata/golden/`.

```go
func TestChargeJSON(t *testing.T) {
    charge := testutil.SampleCharge()
    got := testutil.MustJSON(charge)

    golden := testutil.LoadFixtureBytes(t, "golden/sample_charge.json")
    assert.JSONEq(t, string(golden), string(got))
}
```

Update golden files by running tests with `-update` flag (implement in test setup).

## TypeScript API Testing

### File Naming

- Source: `src/modules/transactions/transactions.service.ts`
- Test: `test/modules/transactions/transactions.service.spec.ts`

### Test Structure

Use Jest with NestJS testing utilities.

```typescript
describe('TransactionsService', () => {
  let service: TransactionsService;
  let fabricGateway: MockFabricGateway;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        TransactionsService,
        { provide: FabricGatewayService, useClass: MockFabricGateway },
      ],
    }).compile();

    service = module.get(TransactionsService);
    fabricGateway = module.get(FabricGatewayService);
  });

  describe('submitCharge', () => {
    it('should submit a valid charge', async () => {
      const charge = ChargeFixture.valid();
      fabricGateway.submitTransaction.mockResolvedValue(Buffer.from('{}'));

      const result = await service.submitCharge(charge);

      expect(result.status).toBe('pending');
      expect(fabricGateway.submitTransaction).toHaveBeenCalledWith(
        'niop', 'CreateCharge', expect.any(String)
      );
    });

    it('should reject a charge with missing agency', async () => {
      const charge = ChargeFixture.missingAgency();

      await expect(service.submitCharge(charge)).rejects.toThrow('awayAgencyID');
    });
  });
});
```

## Test Data Management

### Pre-committed Fixtures

These are committed to the repo and always available:

| File | Records | Use |
|---|---|---|
| `testdata/account.json` | 999 | Account lookups, tag-account associations |
| `testdata/niop-samples/*.xml` | 5 | XML schema validation, protocol parsing |

### Generated Fixtures

Generated by `tools/data-generation/simple_data_gen.py`. Not committed (empty files in repo). Generate before running integration tests:

```bash
cd tools/data-generation
python3 simple_data_gen.py 300
cp tags.json toll_charges.json ../../chaincode/testdata/
```

### Test Factories

Use the `testutil` package factories (`SampleCharge()`, `SampleTag()`, etc.) for unit tests. These return minimal valid objects that can be modified per test case:

```go
charge := testutil.SampleCharge()
charge["amount"] = 0.0  // test zero amount
charge["status"] = "invalid_status"  // test invalid status
```

## Coverage

### Targets

| Component | Minimum Coverage |
|---|---|
| Chaincode models | 90% |
| Chaincode contract functions | 85% |
| Shared utilities (encryption, validation) | 95% |
| API services | 80% |
| API controllers | 70% |

### Running with Coverage

```bash
# Go chaincode
cd chaincode/niop && go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# TypeScript API
cd api && npm run test:cov
```

Coverage output directories are gitignored.

## CI/CD Integration

When GitHub Actions workflows are created (`.github/workflows/`), every push and PR must:

1. Run `make lint`
2. Run `make test`
3. Report coverage
4. Fail the build if coverage drops below targets

## Adding a New Test

1. Identify the function or behavior to test
2. Create (or add to) the `_test.go` or `.spec.ts` file next to the source
3. Use `testutil` helpers — don't write raw stub setup
4. Follow the Arrange/Act/Assert pattern
5. Name the test after the behavior: `TestCreateCharge_RejectsDuplicate`
6. If the test needs new fixture data, add it to `testutil/fixtures.go` as a factory function
7. If the test needs golden file comparison, add the expected output to `testdata/golden/`
8. Run `make test` to verify
9. Check coverage: `go test -cover ./...`
