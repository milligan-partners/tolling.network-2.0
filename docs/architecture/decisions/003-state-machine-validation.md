# ADR-003: State Machine Validation for Status Transitions

## Status

Accepted

## Context

Multiple entities in the system have status fields that follow specific lifecycle rules:

- **Charge**: pending -> posted -> settled (or rejected at various points)
- **Settlement**: draft -> submitted -> accepted -> paid (or disputed/cancelled)
- **Tag**: valid <-> invalid/inactive/lost/stolen (with specific allowed transitions)

Invalid state transitions could cause:
- Financial discrepancies (settling an unposted charge)
- Operational errors (processing a stolen tag)
- Audit failures (unexplained status jumps)

## Decision

We implement **explicit state machine validation** at the model layer:

1. Each model with status defines valid statuses as constants
2. A `ValidateStatusTransition(currentStatus, newStatus)` method enforces allowed transitions
3. Contracts call this validation before persisting status changes

Example from Tag:
```go
var tagStatusTransitions = map[string][]string{
    "valid":    {"invalid", "inactive", "lost", "stolen"},
    "invalid":  {"valid"},
    "inactive": {"valid", "invalid"},
    "lost":     {"valid", "invalid"},
    "stolen":   {"valid", "invalid"},
}

func (t *Tag) ValidateStatusTransition(newStatus string) error {
    allowed, exists := tagStatusTransitions[t.Status]
    if !exists {
        return fmt.Errorf("unknown current status: %s", t.Status)
    }
    if !contains(allowed, newStatus) {
        return fmt.Errorf("cannot transition from %s to %s", t.Status, newStatus)
    }
    return nil
}
```

## Consequences

### Positive

- **Business rule enforcement**: Invalid transitions rejected at chaincode level
- **Auditability**: Clear definition of what transitions are legal
- **Testability**: State machines are easy to unit test exhaustively
- **Documentation**: Transition maps serve as living documentation

### Negative

- **Rigidity**: Changing business rules requires code changes and redeployment
- **Complexity**: Each entity needs its own transition logic
- **No bypass**: Emergency/admin overrides require special handling

### Neutral

- Validation happens in the model layer, keeping contracts thin
- Same status value is rejected (no-op transitions fail explicitly)

## References

- `chaincode/niop/models/tag.go` - Tag status transitions
- `chaincode/niop/models/charge.go` - Charge status transitions
- `chaincode/niop/models/settlement.go` - Settlement status transitions
