# Tolling.Network Technical Design

## 1. Data Model

### Entity Relationships

```
Agency (1) ──┬── (*) Tag           [world state]
             ├── (*) Charge        [private data collection]
             ├── (*) Correction    [private data collection]
             ├── (*) Settlement    [private data collection]
             ├── (*) Reconciliation [world state]
             └── (*) Acknowledgement [world state]
```

### Storage Patterns

| Entity          | Storage Location           | Visibility                    |
|-----------------|----------------------------|-------------------------------|
| Agency          | World state                | All network participants      |
| Tag             | World state                | All network participants      |
| Charge          | Private data collection    | Bilateral (away + home agency)|
| Correction      | Private data collection    | Bilateral (away + home agency)|
| Settlement      | Private data collection    | Bilateral (payor + payee)     |
| Reconciliation  | World state                | All network participants      |
| Acknowledgement | World state                | All network participants      |

### Key Patterns

Each entity uses a prefix-based key for efficient range queries:

| Entity          | Key Pattern                              | Example                           |
|-----------------|------------------------------------------|-----------------------------------|
| Agency          | `AGENCY_{agencyID}`                      | `AGENCY_TCA`                      |
| Tag             | `TAG_{tagSerialNumber}`                  | `TAG_E470123456789`               |
| Charge          | `CHARGE_{chargeID}`                      | `CHARGE_TCA-2025-001`             |
| Correction      | `CORRECTION_{chargeID}_{seqNo:03d}`      | `CORRECTION_TCA-2025-001_001`     |
| Settlement      | `SETTLEMENT_{settlementID}`              | `SETTLEMENT_TCA-HCTRA-2025-01`    |
| Reconciliation  | `RECON_{chargeID}`                       | `RECON_TCA-2025-001`              |
| Acknowledgement | `ACK_{acknowledgementID}`                | `ACK_STVL-TCA-2025-001`           |

### Collection Naming Convention

Private data collections use a bilateral naming pattern with agency IDs sorted alphabetically:

```
charges_{agencyA}_{agencyB}   where agencyA < agencyB alphabetically
```

Examples:
- Charges between TCA and HCTRA → `charges_HCTRA_TCA`
- Charges between E470 and TCA → `charges_E470_TCA`
- Settlements and corrections share the same collection as their related charges

## 2. Chaincode Architecture

### Contract Structure

One contract per entity type, each extending `contractapi.Contract`:

```
niop/
├── agency_contract.go       # AgencyContract
├── tag_contract.go          # TagContract
├── charge_contract.go       # ChargeContract
├── correction_contract.go   # CorrectionContract
├── settlement_contract.go   # SettlementContract
├── reconciliation_contract.go # ReconciliationContract
├── acknowledgement_contract.go # AcknowledgementContract
└── models/
    ├── agency.go
    ├── tag.go
    ├── charge.go
    ├── correction.go
    ├── settlement.go
    ├── reconciliation.go
    └── acknowledgement.go
```

### Validation Approach

Two-level validation:

1. **Model-level validation** (`Validate()` method on each model):
   - Field presence (required fields)
   - Field format (valid enum values, ranges)
   - Internal consistency (e.g., `awayAgencyID != homeAgencyID`)

2. **Contract-level business rules**:
   - Existence checks (entity must/must not exist)
   - State transitions (`ValidateStatusTransition()`)
   - Cross-entity validation (e.g., referenced agency exists)

### Error Handling

- All errors wrap the underlying error with context: `fmt.Errorf("context: %w", err)`
- Validation errors are descriptive: `"invalid tagStatus \"foo\": must be one of [valid invalid inactive lost stolen]"`
- Not-found errors are explicit: `"tag ABC123 not found"`

## 3. Indexing Strategy

### Overview

CouchDB indexes are required for efficient queries on non-key fields. Without indexes, CouchDB performs full collection scans which become prohibitively slow as data grows.

All indexed queries include `docType` as the first field. This is a standard Fabric pattern that:
- Enables type-safe queries across heterogeneous world state
- Allows compound indexes for specific entity types
- Follows CouchDB's leftmost prefix rule for index utilization

### World State Indexes

| Entity          | Index Name                  | Fields                            | Query Method                          |
|-----------------|-----------------------------|-----------------------------------|---------------------------------------|
| Tag             | indexTagByAgency            | `docType`, `tagAgencyID`          | `GetTagsByAgency`                     |
| Tag             | indexTagByStatus            | `docType`, `tagStatus`            | (future: filter by status)            |
| Tag             | indexTagByHomeAgency        | `docType`, `homeAgencyID`         | (future: TVL queries)                 |
| Reconciliation  | indexReconByAgency          | `docType`, `homeAgencyID`         | `GetReconciliationsByAgency`          |
| Reconciliation  | indexReconByDisposition     | `docType`, `postingDisposition`   | `GetReconciliationsByDisposition`     |
| Acknowledgement | indexAckBySubmissionType    | `docType`, `submissionType`       | `GetAcknowledgementsBySubmissionType` |
| Acknowledgement | indexAckByReturnCode        | `docType`, `returnCode`           | `GetAcknowledgementsByReturnCode`     |

### Private Data Collection Indexes

Private data collections use the same index structure but are deployed per-collection. Since collections are dynamically created based on agency pairs, indexes are defined as templates:

| Entity     | Index Name                | Fields                         | Use Case                              |
|------------|---------------------------|--------------------------------|---------------------------------------|
| Charge     | indexChargeByStatus       | `docType`, `status`            | Filter charges by status              |
| Charge     | indexChargeByExitDate     | `docType`, `exitDateTime`      | Date range queries                    |
| Settlement | indexSettlementByStatus   | `docType`, `status`            | Filter settlements by status          |
| Settlement | indexSettlementByPeriod   | `docType`, `periodStart`       | Date range queries                    |
| Correction | indexCorrectionByCharge   | `docType`, `originalChargeID`  | Find corrections for a charge         |

### Index File Format

Indexes are defined in JSON files under `META-INF/statedb/couchdb/indexes/`:

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

### docType Convention

Each entity sets its `docType` field to a lowercase singular noun:

| Entity          | docType           |
|-----------------|-------------------|
| Agency          | `agency`          |
| Tag             | `tag`             |
| Charge          | `charge`          |
| Correction      | `correction`      |
| Settlement      | `settlement`      |
| Reconciliation  | `reconciliation`  |
| Acknowledgement | `acknowledgement` |

### Rich Query Pattern

Contracts use `GetQueryResult()` with CouchDB selectors instead of range-scan-and-filter:

```go
// Indexed query
func (c *TagContract) GetTagsByAgency(ctx contractapi.TransactionContextInterface, tagAgencyID string) ([]*models.Tag, error) {
    query := `{"selector":{"docType":"tag","tagAgencyID":"` + tagAgencyID + `"}}`
    resultsIterator, err := ctx.GetStub().GetQueryResult(query)
    // ...
}
```

For private data:
```go
func (c *ChargeContract) GetChargesByStatus(ctx contractapi.TransactionContextInterface, collection string, status string) ([]*models.Charge, error) {
    query := `{"selector":{"docType":"charge","status":"` + status + `"}}`
    resultsIterator, err := ctx.GetStub().GetPrivateDataQueryResult(collection, query)
    // ...
}
```

## 4. API Design

*Stub for future - NestJS + Fabric Gateway*

### Gateway SDK Integration

The API will use `@hyperledger/fabric-gateway` (Fabric 2.4+ Gateway SDK):
- gRPC connection to peer
- Client identity from wallet
- Contract evaluation and submission

### REST Endpoints

To be defined. Expected patterns:
- `GET /agencies` - List agencies
- `GET /agencies/:id` - Get agency
- `POST /agencies` - Create agency
- `GET /tags` - List tags (with query params for filtering)
- `POST /charges` - Submit charge batch
- etc.

### Authentication/Authorization

To be defined. Considerations:
- mTLS for client authentication
- Agency-scoped access control
- Rate limiting per agency
