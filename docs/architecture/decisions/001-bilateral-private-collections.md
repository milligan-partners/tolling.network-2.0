# ADR-001: Bilateral Private Data Collections

## Status

Accepted

## Context

Tolling interoperability involves sensitive financial data (charges, settlements, corrections) exchanged between pairs of agencies. In a multi-agency Hyperledger Fabric network:

1. Agency A should not see transactions between Agency B and Agency C
2. Both parties in a bilateral relationship need access to the same data
3. The collection naming must be deterministic so either party can locate the data

Fabric supports Private Data Collections (PDCs) which store data off the main ledger, visible only to authorized organizations.

## Decision

We use **bilateral private data collections** with alphabetically-sorted naming:

```
charges_{smaller_agency_id}_{larger_agency_id}
```

For example, transactions between `TCA` and `BATA` are stored in `charges_BATA_TCA` (BATA < TCA alphabetically).

The `CollectionName()` method on models handles this:

```go
func (c *Charge) CollectionName() string {
    if c.AwayAgencyID < c.HomeAgencyID {
        return fmt.Sprintf("charges_%s_%s", c.AwayAgencyID, c.HomeAgencyID)
    }
    return fmt.Sprintf("charges_%s_%s", c.HomeAgencyID, c.AwayAgencyID)
}
```

All bilateral data types (Charge, Settlement, Correction) use this same pattern.

## Consequences

### Positive

- **Privacy**: Agencies only see their own bilateral transactions
- **Symmetry**: Either agency can query using the same collection name
- **Deterministic**: No coordination needed; both parties compute the same name
- **Scalable**: N agencies = N*(N-1)/2 collections, which is manageable

### Negative

- **Collection proliferation**: Each new agency pair requires a new collection definition in `collections_config.json`
- **No cross-pair queries**: Cannot query "all charges for Agency X" in a single query (must query each bilateral collection separately)
- **Deployment complexity**: Adding a new agency requires updating collection configs and redeploying

### Neutral

- Settlement and Correction data uses the same collection as Charge data (they're all in `charges_*` collections with different key prefixes)

## References

- Hyperledger Fabric Private Data: https://hyperledger-fabric.readthedocs.io/en/latest/private-data/private-data.html
- `chaincode/niop/models/charge.go` - CollectionName() implementation
