# Private Data Collections

> **WARNING: LEGACY REFERENCE ONLY — REVIEW POLICIES BEFORE USE**

These collection configuration files define Hyperledger Fabric private data collections for toll interoperability data.

## Security Issues

### 1. Overly Permissive OR Policies

The current configs use `OR` logic for shared collections:

```json
"policy": "OR('Org1.member', 'Org2.member', 'Org3.member')"
```

This means **any single org** can read all data in the collection. For bilateral data (charges between two specific agencies), this should use `AND` to require both parties:

```json
"policy": "AND('Org1.member', 'Org2.member')"
```

**Review each collection against the data ownership table in plan.md Section 2:**

| Collection Type | Current Policy | Should Be |
|----------------|---------------|-----------|
| `license_plate_status` | `OR(all orgs)` | `OR(all orgs)` — OK for TVL sharing |
| `tag_status` | `OR(all orgs)` | `OR(all orgs)` — OK for TVL sharing |
| `*_toll_charges_*` | `OR(single org)` | Bilateral `AND(away, home)` for charges |
| `*_recon_*` | `OR(single org)` | Bilateral `AND(away, home)` for reconciliation |

### 2. blockToLive: 0 (No Expiration)

All collections set `blockToLive: 0`, meaning private data never expires. This causes:
- Unbounded ledger growth
- Potential regulatory non-compliance (data retention requirements)

**2.0 must set appropriate `blockToLive` based on:**
- Toll industry data retention requirements (typically 3-7 years)
- State-specific regulations (see plan.md Section 8)

Example for 7-year retention at ~10 blocks/minute:
```json
"blockToLive": 36792000
```

### 3. Single-Org Policies Don't Match Data Model

Collections like `org1_toll_charges_source` use `OR('Org1.member')` — only Org1 can access. But toll charges are bilateral (away agency creates, home agency reads). The 2.0 collection design should use:

```json
{
  "name": "charges_Org1_Org2",
  "policy": "AND('Org1.member', 'Org2.member')",
  "requiredPeerCount": 2,
  "maxPeerCount": 4,
  "blockToLive": 36792000,
  "memberOnlyRead": true,
  "memberOnlyWrite": true
}
```

## For 2.0 Development

Redesign collections to match the bilateral data ownership model defined in plan.md Section 2:
- Dynamic collection creation for each agency pair
- `AND` policies for bilateral data
- Appropriate `blockToLive` for regulatory compliance
- `requiredPeerCount: 2` for production durability
