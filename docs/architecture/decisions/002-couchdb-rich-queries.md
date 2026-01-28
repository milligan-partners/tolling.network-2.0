# ADR-002: CouchDB Rich Queries with DocType Pattern

## Status

Accepted

## Context

Hyperledger Fabric supports two state database options:

1. **LevelDB**: Key-value only, supports range queries by key prefix
2. **CouchDB**: JSON document store, supports rich queries via selectors

Our chaincode needs to query data by various attributes:
- Tags by issuing agency, status, or home agency
- Reconciliations by agency or posting disposition
- Acknowledgements by submission type or return code

With LevelDB, we would need to:
- Design composite keys for every query pattern (e.g., `TAG_STATUS_valid_TCA_123`)
- Maintain multiple key entries per record for different query paths
- Perform client-side filtering after range scans

## Decision

We use **CouchDB as the state database** with:

1. **DocType field**: Every model includes a `docType` field set automatically via timestamp methods
2. **Composite indexes**: CouchDB indexes on `(docType, queryField)` for efficient queries
3. **Rich queries**: Contracts use `GetQueryResult()` with JSON selectors

Example query:
```go
query := `{"selector":{"docType":"tag","tagAgencyID":"TCA"}}`
resultsIterator, err := ctx.GetStub().GetQueryResult(query)
```

Index definition (`META-INF/statedb/couchdb/indexes/indexTagByAgency.json`):
```json
{
  "index": {"fields": ["docType", "tagAgencyID"]},
  "ddoc": "indexTagByAgencyDoc",
  "name": "indexTagByAgency",
  "type": "json"
}
```

## Consequences

### Positive

- **Flexible queries**: Query by any indexed field without key redesign
- **Readable queries**: JSON selectors are self-documenting
- **Single record**: No duplicate key entries for different query patterns
- **Standard pattern**: DocType is a well-known Fabric/CouchDB idiom

### Negative

- **CouchDB dependency**: Cannot use LevelDB; increases infrastructure complexity
- **Index maintenance**: Must create/update index files when adding query patterns
- **Query performance**: Rich queries can be slower than direct key lookups
- **Eventual consistency**: CouchDB indexes update asynchronously (typically milliseconds)

### Neutral

- DocType is set automatically in `SetTimestamps()`, `SetCreatedAt()`, and `TouchUpdatedAt()` methods
- Private data collections also support rich queries via `GetPrivateDataQueryResult()`

## References

- Fabric CouchDB as State Database: https://hyperledger-fabric.readthedocs.io/en/latest/couchdb_as_state_database.html
- `chaincode/niop/META-INF/statedb/couchdb/indexes/` - Index definitions
- `docs/architecture/design.md` - Indexing strategy section
