# ADR-004: JSON String Parameters for Chaincode API

## Status

Accepted

## Context

Hyperledger Fabric chaincode functions receive parameters as strings. For complex objects like Charge or Settlement, we need to pass structured data. Options include:

1. **Positional parameters**: `CreateCharge(chargeID, awayAgency, homeAgency, amount, ...)`
2. **JSON string parameter**: `CreateCharge(jsonString)`
3. **Protobuf**: Binary serialization

Considerations:
- Fabric SDKs (Go, Node, Java) all support string parameters natively
- Complex objects have 10-20+ fields
- API should be consistent across all entities

## Decision

We use **single JSON string parameters** for create/update operations:

```go
func (c *ChargeContract) CreateCharge(ctx contractapi.TransactionContextInterface, chargeJSON string) error {
    var charge models.Charge
    if err := json.Unmarshal([]byte(chargeJSON), &charge); err != nil {
        return fmt.Errorf("failed to parse charge JSON: %w", err)
    }
    // ... validation and persistence
}
```

For read operations, we use simple typed parameters:
```go
func (c *ChargeContract) GetCharge(ctx contractapi.TransactionContextInterface,
    chargeID string, agencyA string, agencyB string) (*models.Charge, error)
```

## Consequences

### Positive

- **Flexibility**: Adding optional fields doesn't change function signature
- **Self-documenting**: JSON field names are explicit
- **Client-friendly**: Easy to construct from any language
- **Validation centralized**: Model's `Validate()` method handles all field validation

### Negative

- **No compile-time safety**: Typos in field names fail at runtime
- **Parsing overhead**: JSON unmarshal on every call
- **Error messages**: Parse errors may be less clear than type errors

### Neutral

- Return types are still strongly typed (`*models.Charge`, `[]*models.Tag`)
- Validation errors include specific field names for debugging

## References

- Fabric Contract API: https://hyperledger-fabric.readthedocs.io/en/latest/chaincode4ade.html
- All `*_contract.go` files follow this pattern
