# Next Session: Design Document + CouchDB Indexes

## Context

We decided to create a centralized design document (`docs/architecture/design.md`) instead of scattering technical decisions across README files. The first section to write is the indexing strategy for CouchDB, followed by implementing the indexes.

## Task

### 1. Create `docs/architecture/design.md`

Structure:
```
# Tolling.Network Technical Design

## 1. Data Model
- Entity relationships
- Storage patterns (world state vs. private data collections)
- Key patterns (AGENCY_, TAG_, CHARGE_, etc.)
- Collection naming convention (bilateral: charges_{A}_{B} alphabetically sorted)

## 2. Chaincode Architecture
- Contract structure (one contract per entity)
- Validation approach (model-level Validate(), contract-level business rules)
- Error handling patterns

## 3. Indexing Strategy  <-- Start here
- Which fields need indexes and why
- World state indexes vs. private data collection indexes
- docType pattern for type-based queries

## 4. API Design
- (Stub for future - NestJS + Fabric Gateway)
```

### 2. Indexing Strategy Content

Based on research from the contracts, these queries need indexes:

**World State Entities:**

| Entity | Query Method | Field(s) to Index |
|--------|--------------|-------------------|
| Tag | `GetTagsByAgency` | `tagAgencyID` |
| Tag | (future: by status) | `tagStatus` |
| Tag | (future: by home agency) | `homeAgencyID` |
| Reconciliation | `GetReconciliationsByAgency` | `homeAgencyID` |
| Reconciliation | `GetReconciliationsByDisposition` | `postingDisposition` |
| Acknowledgement | `GetAcknowledgementsBySubmissionType` | `submissionType` |
| Acknowledgement | `GetAcknowledgementsByReturnCode` | `returnCode` |

**Private Data Collections:**

| Entity | Collection Pattern | Field(s) to Index |
|--------|-------------------|-------------------|
| Charge | `charges_{A}_{B}` | `status`, `exitDateTime` |
| Settlement | `charges_{A}_{B}` | `status`, `periodStart` |

**Design Decision:** Add `docType` field to all entities. This is standard Fabric practice for CouchDB queries:
- Enables `{"selector": {"docType": "tag", "tagAgencyID": "TCA"}}`
- Requires updating models to include `DocType string json:"docType"`
- Requires updating contracts to set docType on create

### 3. Implement Indexes

Directory structure:
```
chaincode/niop/META-INF/statedb/couchdb/
├── indexes/
│   ├── indexTagByAgency.json
│   ├── indexTagByStatus.json
│   ├── indexTagByHomeAgency.json
│   ├── indexReconByAgency.json
│   ├── indexReconByDisposition.json
│   ├── indexAckBySubmissionType.json
│   └── indexAckByReturnCode.json
└── collections/
    └── charges_{A}_{B}/  # Template - actual collections are dynamic
        └── indexes/
            ├── indexChargeByStatus.json
            └── indexSettlementByStatus.json
```

Index file format (example):
```json
{
  "index": {
    "fields": ["docType", "tagAgencyID"]
  },
  "ddoc": "indexTagByAgencyDoc",
  "name": "indexTagByAgency",
  "type": "json"
}
```

### 4. Update Contracts to Use Rich Queries

Replace range-scan-and-filter patterns with CouchDB rich queries:

```go
// Before (inefficient)
func (c *TagContract) GetTagsByAgency(ctx contractapi.TransactionContextInterface, tagAgencyID string) ([]*models.Tag, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("TAG_", "TAG_~")
    // ... iterate and filter by tagAgencyID
}

// After (indexed query)
func (c *TagContract) GetTagsByAgency(ctx contractapi.TransactionContextInterface, tagAgencyID string) ([]*models.Tag, error) {
    query := fmt.Sprintf(`{"selector":{"docType":"tag","tagAgencyID":"%s"}}`, tagAgencyID)
    resultsIterator, err := ctx.GetStub().GetQueryResult(query)
    // ... iterate results (already filtered)
}
```

### 5. Update Models to Include docType

Each model needs:
1. Add `DocType string json:"docType"` field
2. Set docType in constructor or SetCreatedAt/TouchUpdatedAt methods
3. Update tests

## Files to Modify

- `docs/architecture/design.md` (create)
- `chaincode/niop/models/*.go` (add docType field)
- `chaincode/niop/*_contract.go` (use rich queries, set docType)
- `chaincode/niop/META-INF/statedb/couchdb/indexes/*.json` (create)
- `chaincode/niop/models/*_test.go` (update for docType)
- `chaincode/niop/*_contract_test.go` (update for docType)

## Order of Operations

1. Write design.md with indexing strategy section
2. Update models to add docType field
3. Update model tests
4. Create index JSON files
5. Update contracts to use rich queries and set docType
6. Update contract tests
7. Run all tests to verify

## Reference

Legacy indexes found in:
- `/Users/mattmilligan/Documents/Work/Code/Tolling-Network/private-dev/Kubernetes/artifacts/chaincode/cronChaincode/META-INF/statedb/couchdb/indexes/`

Example format:
```json
{"index":{"fields":["docType","hostAgency"]},"ddoc":"indexHostAgencyDoc","name":"indexHostAgency","type":"json"}
```
