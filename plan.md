# Tolling.Network 2.0 — Product & Development Plan

**Status:** In Progress
**Last Updated:** January 27, 2026

---

## 1. Value Proposition

*Why does Tolling.Network need to exist? What problem does it solve, and why is a distributed ledger the right approach?*

### The Problem

Toll interoperability in the United States is governed through a layered structure of consortiums and national coordination:

- **NIOP** (National Interoperability) sits at the top, defining rules for how four regional hubs exchange data and settle transactions.
- **Four regional hubs** operate beneath NIOP: E-ZPass/EZIOP (Northeast, 39 agencies), CUSIOP (Central US — Texas, Kansas, Oklahoma), SEIOP (Southeast, anchored by Florida's central CSC), and the Western Region/WRTO (including California's FasTrak).
- **Individual toll agencies** within each hub run their own back-office systems, set their own toll rates and business rules, and manage their own customer accounts.

This structure creates three categories of problems:

**Political friction.** Every consortium struggles with governance. Agencies want autonomy over their own rules — toll rates, grace periods, dispute resolution, violation policies — but must also conform to consortium-level agreements. Adding national interoperability through NIOP introduces a third layer of rules. Today, these layers are enforced through committee meetings, bilateral agreements, and manual processes. Smaller agencies often lack the leverage or resources to shape the rules that govern them.

**Technical fragmentation.** Each agency runs its own back-office system, typically from one of a few vendors (Conduent, Quarterhill, Kapsch). Data exchange between agencies and hubs happens via nightly SFTP transfers of XML files. Tag validation lists take 24-72 hours to propagate. Financial settlement happens at best monthly, often with 30-45 day lag. Reconciliation requires matching separate copies of the same data across organizations using a series of correction reports. There is no shared source of truth.

**Cost and inefficiency.** Electronic toll transactions cost $0.05-$0.10 each to process, but image-based (pay-by-mail) transactions cost $0.35-$0.45. Hundreds of thousands of transactions can become stuck or lost between systems. Each hub pair negotiates its own reconciliation method and frequency. The E-ZPass network alone processes $16.8 billion in annual revenue across 59 million transponders, with $6.2 billion in inter-agency transfers — all flowing through batch processes and manual reconciliation.

The federal government mandated nationwide interoperability by October 2016 (MAP-21). That deadline was missed. The FAST Act continued the mandate but added no enforcement. A decade later, true coast-to-coast interoperability remains incomplete.

### The Solution

Tolling.Network is an open-source distributed ledger that replaces the hub-and-spoke batch processing model with a shared, permissioned blockchain where toll agencies transact directly.

The key design principle: **agencies keep control of their own rules while operating on shared infrastructure.**

Each toll agency runs its own node on the network. Smart contracts (chaincode) encode business rules at three levels:

1. **Agency-level rules** — An agency's own toll rates, grace periods, violation policies, and account management logic. Each org controls its own chaincode.
2. **Consortium-level rules** — The agreed-upon rules for a regional group (e.g., E-ZPass reconciliation procedures, FasTrak data-sharing policies). Encoded in shared chaincode that consortium members endorse together.
3. **National-level rules** — NIOP transaction formats, settlement procedures, and dispute resolution. Encoded in chaincode endorsed by all participating hubs.

This maps directly to how the industry actually works — layered governance with local autonomy — but replaces committee politics and manual enforcement with code that executes automatically.

Transactions are recorded on the shared ledger in near-real-time instead of nightly batch files. Settlement can happen daily or even per-transaction instead of monthly. Disputes reference a single immutable record instead of requiring agencies to reconcile separate copies of the data.

### Why Hyperledger Fabric

Fabric is the right platform for this specific problem because its architecture mirrors the industry's organizational structure:

- **Permissioned network.** Only authorized toll agencies participate. No public blockchain, no cryptocurrency, no anonymous actors. This is what government agencies require.
- **Organizations as first-class citizens.** Each agency is a Fabric "organization" with its own identity, its own peers, and its own certificate authority. Agencies own their infrastructure.
- **Channels for privacy.** Fabric channels allow subsets of agencies to transact privately. California agencies restricted by state PII laws can participate on channels that never expose data to out-of-state operators. Bilateral relationships (Agency A settles with Agency B) stay private from Agency C.
- **Private data collections.** Within a channel, agencies can share data selectively — hashes on the ledger for verification, actual data only to authorized parties.
- **Chaincode endorsement policies.** Business rules are enforced by the organizations that agree to them. A consortium-level rule requires endorsement from consortium members. An agency-level rule only requires that agency's endorsement. This is how layered governance becomes enforceable code.
- **No single point of control.** No one agency, vendor, or hub operator owns the network. The ordering service can be distributed. Governance is built into the protocol, not delegated to a committee chair.

### Who Benefits

**Toll agencies** get a shared platform where they keep control of their own business rules, reduce back-office costs, settle faster, and resolve disputes against a single source of truth — without being locked into a single vendor's system.

**Consortiums** (E-ZPass IAG, CUSIOP, SEIOP, WRTO/FasTrak) get an enforceable way to implement their rules across members. Compliance becomes automatic rather than political. New members onboard by deploying a node and agreeing to the consortium's chaincode, not by negotiating bilateral agreements with every other member.

**Smaller agencies** get access to the same interoperability infrastructure as large agencies without the cost of building hub connections or the political disadvantage of negotiating with larger neighbors.

**The traveling public** benefits from faster account updates, fewer billing errors, and eventually seamless coast-to-coast tolling — the promise Congress mandated in 2012 but the industry hasn't fully delivered.

---

## 2. Data Model

*What data moves through the network? What are the core entities, their relationships, and their lifecycle?*

**Design principles:**

1. **Toll-first, mobility-open.** The core entities are designed around toll interoperability (the immediate product), but the abstractions are general enough to support congestion pricing, managed lanes, parking, transit fare integration, and other cross-jurisdictional mobility charges without rearchitecting.

2. **Hub-compatible, agency-native (Option C).** The network is peer-to-peer at the protocol level — every agency is a first-class Fabric organization that can transact directly with any other agency. But the system speaks NIOP, IAG, and CTOC data formats natively. Agencies can join the network directly or route through their existing hub. Hubs that want to participate act as aggregators, not required middlemen. This provides a migration path: agencies move at their own pace from hub-routed to direct participation.

### Architecture Decision: Hub-Compatible, Agency-Native

The existing toll interoperability infrastructure uses a hub-and-spoke model where agencies connect to a regional hub, and hubs exchange data with each other. Tolling.Network does not replicate this architecture. Instead:

- **Every agency is a Fabric org.** Each agency runs its own peer nodes, has its own certificate authority, and controls its own identity. There is no architectural distinction between a "large" and "small" agency on the network.
- **Hubs are optional aggregators, not gatekeepers.** A hub (e.g., E-ZPass IAG, CUSIOP) can participate as a Fabric org that aggregates transactions for its member agencies. But an agency can also connect directly without going through a hub. The ledger doesn't care.
- **NIOP/IAG/CTOC protocols are chaincode, not infrastructure.** The NIOP ICD record types (TB01, TC01, VB01, etc.), IAG Inter-CSC file formats, and CTOC report structures (CTOC-1, CTOC-2, CTOC-5, CTOC-6) are implemented as chaincode data structures and validation rules. The data model understands these formats natively — agencies submit the same logical data they do today, but as ledger transactions instead of XML files over SFTP.
- **Two connectivity modes:**
  - **Direct mode** — The agency runs its own Fabric peer nodes, has its own certificate authority, and submits transactions directly to the ledger.
  - **Hub-routed mode** — The agency's hub operates Fabric peers on its behalf. The agency connects to the hub's API to submit and receive data. The hub writes to the ledger as the Fabric org. The agency doesn't run blockchain infrastructure, but the data model, validation rules, and endorsement policies are the same. This is an operational choice about who runs the compute — not an architectural difference in how data is stored or governed.
- **Consortiums are governance layers, not routing layers.** A consortium (E-ZPass, CUSIOP, WRTO/FasTrak) is represented as a Fabric channel with shared chaincode that encodes the consortium's rules. Member agencies endorse that chaincode. The consortium enforces rules through endorsement policies, not through controlling data flow.

This approach means agencies, hubs, and consortiums can all coexist on the network. An E-ZPass agency can transact directly with a CUSIOP agency without either hub being in the middle — but both hubs can still see aggregated reports through their consortium channels if their governance rules require it.

### Core Entities

#### Agency

The fundamental organizational unit. Every other entity belongs to or is scoped by an agency. Both toll operators and hubs are represented as agencies with different roles.

| Field | Type | Description |
|---|---|---|
| agencyID | string | Unique identifier (e.g., `TCA`, `HCTRA`, `NTTA`, `BATA`) |
| name | string | Full name (e.g., "Transportation Corridor Agencies") |
| consortium | string[] | Consortium memberships (`EZIOP`, `CUSIOP`, `SEIOP`, `WRTO`) — an agency can belong to multiple |
| hubID | string | NIOP hub identifier (for hub-routed agencies) |
| state | string | State jurisdiction |
| role | string | `toll_operator`, `hub`, `clearinghouse`, `transit_authority` |
| connectivityMode | string | `direct`, `hub_routed`, `both` |
| status | string | `active`, `suspended`, `onboarding` |
| capabilities | string[] | `toll`, `congestion_pricing`, `parking`, `transit` |
| protocolSupport | string[] | Protocols this agency supports: `niop_1.02`, `niop_2.0`, `iag_1.51n`, `iag_1.60`, `ctoc_rev_a` |

**Storage:** World state (public to all channel members).

#### Account

A customer account managed by a home agency. Accounts are the anchor for tags, plates, and transaction history.

| Field | Type | Description |
|---|---|---|
| accountID | string | Home agency's account identifier |
| homeAgencyID | string | Agency that owns/manages this account |
| accountStatus | string | `active`, `inactive`, `suspended`, `closed` |
| fleetIndicator | boolean | Whether this is a fleet/commercial account |
| createdAt | timestamp | Account creation date |
| updatedAt | timestamp | Last modification date |

**Storage:** Private data collection (home agency + authorized counterparties). Account details are PII-adjacent and must not be visible network-wide.

**Note:** The account itself does not contain customer PII (name, address, payment method). That stays in the agency's back-office system. The ledger only carries the interoperability-relevant account metadata.

#### Tag

A transponder or device associated with an account. Tags are the primary identifier for electronic toll collection.

| Field | Type | Description |
|---|---|---|
| tagSerialNumber | string | Unique tag identifier |
| tagAgencyID | string | Agency that issued the tag |
| homeAgencyID | string | Agency that manages the associated account |
| accountID | string | Associated account |
| tagStatus | string | `valid`, `invalid`, `inactive`, `lost`, `stolen` |
| tagType | string | `single`, `loaded`, `flex`, `generic` |
| tagClass | int | Vehicle class associated with tag |
| tagProtocol | string | `sego`, `6c`, `tdm` |
| discountPlans | object[] | Active discount plans (type, start, end) |
| plates | object[] | Associated license plates (country, state, number, type, effective dates) |
| updatedAt | timestamp | Last status change |

**Storage:** Private data collection (`tag_status`). Tag validation lists (TVLs) are shared between home and away agencies for transaction processing. Hashes stored on-chain; full records in private data.

**Lifecycle:** Tags are created by the issuing agency, shared via TVL updates, and updated when status changes (e.g., account closure, reported stolen). Away agencies need to know tag status to process transactions but don't need account details.

#### Charge

A toll or mobility charge generated when a vehicle uses a facility. This is the central transaction entity — named "Charge" rather than "TollCharge" to support future mobility use cases.

| Field | Type | Description |
|---|---|---|
| chargeID | string | Unique transaction identifier |
| chargeType | string | `toll_tag`, `toll_video`, `toll_paybyplate`, `congestion`, `parking`, `transit` |
| recordType | string | NIOP record type (`TB01`, `TC01`, `TC02`, `VB01`, `VC01`, `VC02`) or equivalent |
| protocol | string | Source protocol: `niop`, `iag`, `ctoc`, `native` |
| awayAgencyID | string | Agency where the charge was incurred (facility operator) |
| homeAgencyID | string | Agency responsible for the account/tag |
| submittedVia | string | `direct` or hub agency ID (e.g., `EZIOP`) — how the charge entered the network |
| tagSerialNumber | string | Tag that was read (if tag-based) |
| plateCountry | string | License plate country (if plate-based) |
| plateState | string | License plate state |
| plateNumber | string | License plate number |
| facilityID | string | Facility/road identifier |
| plaza | string | Plaza or gantry identifier |
| lane | string | Lane identifier |
| entryPlaza | string | Entry point (closed-system tolls) |
| entryDateTime | timestamp | Entry time (closed-system tolls) |
| exitDateTime | timestamp | Exit/charge time |
| vehicleClass | int | Vehicle classification |
| occupancy | int | Occupancy indicator (for HOV/HOT lanes) |
| amount | decimal | Toll/charge amount |
| fee | decimal | Interoperability processing fee |
| netAmount | decimal | Amount minus fee |
| discountPlanType | string | Applied discount plan (if any) |
| status | string | `pending`, `posted`, `disputed`, `rejected`, `settled` |
| createdAt | timestamp | When the charge was recorded on the ledger |

**Storage:** Private data collection (away agency + home agency bilateral). The away agency creates the charge; the home agency posts it to the customer's account. Only the two agencies involved see the full record. A hash is written to the channel ledger for auditability.

**Protocol compatibility:** The `protocol` field tracks which interop protocol the charge originated from. Chaincode validates the charge against that protocol's rules (e.g., NIOP ICD v1.02 record type validation, IAG Inter-CSC field requirements, CTOC report mapping). The `submittedVia` field tracks whether the charge came directly from an agency or was routed through a hub — this is transparent to the home agency but important for auditing and for hubs that need to track aggregated volumes.

**Lifecycle:**
1. **Created** — Away agency records the charge from its toll system
2. **Submitted** — Charge is written to the ledger and shared with the home agency
3. **Posted** — Home agency posts the charge to the customer's account (or rejects it)
4. **Reconciled** — Both agencies confirm the charge and its posting disposition
5. **Settled** — Financial settlement occurs between agencies

#### Correction

An adjustment to a previously submitted charge. Corrections track the full history of changes to maintain auditability.

| Field | Type | Description |
|---|---|---|
| correctionID | string | Unique correction identifier |
| originalChargeID | string | Reference to the original charge |
| correctionSeqNo | int | Sequence number (0-999, for multiple corrections) |
| correctionReason | string | `C` (correction), `I` (invalid), `L` (late), `T` (technical), `O` (other) |
| resubmitReason | string | `R` (resubmit), `S` (supplement) |
| resubmitCount | int | Number of times resubmitted |
| fromAgencyID | string | Agency submitting the correction |
| toAgencyID | string | Agency receiving the correction |
| recordType | string | Original record type with `A` suffix (e.g., `TB01A`) |
| amount | decimal | Corrected amount |
| createdAt | timestamp | Correction timestamp |

**Storage:** Private data collection (bilateral between the two agencies involved).

#### Reconciliation

The home agency's response to a submitted charge — did it post successfully, and if not, why?

| Field | Type | Description |
|---|---|---|
| reconciliationID | string | Unique reconciliation record identifier |
| chargeID | string | Reference to the original charge |
| homeAgencyID | string | Agency that processed the charge |
| postingDisposition | string | See disposition codes below |
| postedAmount | decimal | Amount actually posted (may differ from charge amount) |
| postedDateTime | timestamp | When the charge was posted |
| adjustmentCount | int | Number of adjustments applied |
| resubmitCount | int | Number of resubmissions |
| flatFee | decimal | Flat processing fee |
| percentFee | decimal | Percentage-based processing fee |
| discountPlanType | string | Discount plan applied at posting |

**Posting disposition codes:**

| Code | Meaning |
|---|---|
| P | Posted successfully |
| D | Duplicate transaction |
| I | Invalid tag or plate |
| N | Not posted (general) |
| S | System or communication issue |
| T | Transaction content/format error |
| C | Tag/plate not on file |
| O | Transaction too old |

**Storage:** Private data collection (bilateral). The reconciliation record is the home agency's authoritative response to the away agency's charge.

#### Acknowledgement

A protocol-level response confirming receipt and validation of a data submission (TVL, transaction batch, correction batch, reconciliation batch).

| Field | Type | Description |
|---|---|---|
| acknowledgementID | string | Unique identifier |
| submissionType | string | What was submitted: `STVL`, `STRAN`, `SCORR`, `SRECON` |
| fromAgencyID | string | Receiving agency |
| toAgencyID | string | Submitting agency |
| returnCode | string | `00` (success) through `13` (see NIOP spec) |
| returnMessage | string | Human-readable description |
| createdAt | timestamp | Acknowledgement timestamp |

**Storage:** World state (on-channel). Acknowledgements are non-sensitive protocol metadata.

#### Settlement

Financial settlement between agencies for a reconciliation period. This entity is new — the legacy code didn't implement settlement.

| Field | Type | Description |
|---|---|---|
| settlementID | string | Unique identifier |
| periodStart | date | Settlement period start |
| periodEnd | date | Settlement period end |
| payorAgencyID | string | Agency that owes money |
| payeeAgencyID | string | Agency that is owed money |
| grossAmount | decimal | Total charge amount for the period |
| totalFees | decimal | Total processing fees |
| netAmount | decimal | Amount to be transferred |
| chargeCount | int | Number of charges in the settlement |
| correctionCount | int | Number of corrections applied |
| status | string | `draft`, `submitted`, `accepted`, `disputed`, `paid` |
| createdAt | timestamp | Settlement creation date |

**Storage:** Private data collection (bilateral between payor and payee).

### Entity Relationships

```
Agency (1)
 ├── manages many: Account
 ├── issues many: Tag
 ├── operates many: Facility/Plaza
 └── participates in: Consortium

Account (1)
 ├── belongs to: Agency (home)
 ├── has many: Tag
 └── has many: Charge (as home agency)

Tag (1)
 ├── belongs to: Account
 ├── issued by: Agency
 └── referenced by: Charge

Charge (1)
 ├── from: Agency (away — facility operator)
 ├── to: Agency (home — account owner)
 ├── references: Tag or Plate
 ├── has many: Correction
 ├── has one: Reconciliation
 └── included in: Settlement

Correction (1)
 └── amends: Charge

Reconciliation (1)
 └── responds to: Charge

Settlement (1)
 ├── between: Agency (payor) and Agency (payee)
 └── covers many: Reconciliation records
```

### Data Ownership

| Entity | Owner | Shared With | Privacy Level |
|---|---|---|---|
| Agency | Network | All channel members | Public |
| Account | Home agency | Counterparty agencies (as needed) | Private (bilateral) |
| Tag | Issuing agency | All agencies (via TVL) | Private (consortium-wide) |
| Charge | Away agency (creator) | Home agency | Private (bilateral) |
| Correction | Submitting agency | Counterparty agency | Private (bilateral) |
| Reconciliation | Home agency | Away agency | Private (bilateral) |
| Acknowledgement | Receiving agency | Submitting agency | On-channel |
| Settlement | Both agencies | Bilateral only | Private (bilateral) |

### Transaction Lifecycle

```
1. TOLL EVENT          Agency B's roadside system reads a tag issued by Agency A
                       ↓
2. TAG LOOKUP          Agency B checks the Tag Validation List for tag status
                       ↓
3. CHARGE CREATED      Agency B creates a Charge record on the ledger
                       (private data: Agency A + Agency B only)
                       ↓
4. CHARGE SUBMITTED    Charge is shared with Agency A (home agency)
                       Agency A sends Acknowledgement (return code 00-13)
                       ↓
5. POSTING             Agency A posts the charge to the customer's account
                       (or rejects it — invalid tag, duplicate, too old, etc.)
                       ↓
6. RECONCILIATION      Agency A writes a Reconciliation record with posting
                       disposition and any fee/amount adjustments
                       ↓
7. CORRECTION          (If needed) Either agency submits a Correction
                       (reason: C/I/L/T/O), triggering re-reconciliation
                       ↓
8. SETTLEMENT          At the end of a settlement period, a Settlement record
                       aggregates all reconciled charges into a net amount
                       ↓
9. PAYMENT             Off-chain: Agency A transfers funds to Agency B
                       Settlement status updated to "paid" on the ledger
```

### Extensibility for Mobility

The data model is designed to extend beyond tolling:

| Future Use Case | How It Maps |
|---|---|
| Congestion pricing | Charge with `chargeType: "congestion"`, plaza = zone ID |
| Managed/HOT lanes | Charge with occupancy field, dynamic pricing in amount |
| Parking | Charge with `chargeType: "parking"`, facility = parking structure |
| Transit fare integration | Charge with `chargeType: "transit"`, tag = contactless card |
| Mileage-based user fees | Charge with `chargeType: "mbuf"`, distance field added |

The key abstraction: a **Charge** is any priced mobility event where the facility operator (away agency) and the account holder's agency (home agency) are different organizations and need to reconcile. The ledger handles the interoperability — the specific pricing logic stays in each agency's system.

### Channel & Network Design (Option C)

The Fabric network topology implements the hub-compatible, agency-native architecture:

#### Channels

| Channel | Members | Purpose | Chaincode |
|---|---|---|---|
| `national` | All agencies and hubs | Network-wide agency registry, protocol versioning, shared reference data | Agency registry, protocol version management |
| `ezpass` | E-ZPass IAG member agencies + EZIOP hub | E-ZPass consortium governance and rules | IAG Inter-CSC validation, E-ZPass business rules |
| `cusiop` | CUSIOP member agencies + CUSIOP hub | Central US consortium governance | CUSIOP business rules, CUSIOP ICD supplement |
| `seiop` | SEIOP member agencies + SEIOP hub | Southeast consortium governance | SEIOP business rules |
| `wrto` | WRTO/FasTrak member agencies | Western region / California governance | CTOC tech spec rules, FasTrak data-sharing policies |
| `interop` | All agencies participating in cross-hub transactions | Cross-consortium charge exchange | NIOP ICD record validation, charge lifecycle, reconciliation, settlement |

#### Private Data Collections (within `interop` channel)

Bilateral private data collections are created dynamically for each agency pair that transacts:

| Collection Pattern | Scope | Contains |
|---|---|---|
| `tvl_{homeAgency}` | Home agency + all away agencies | Tag Validation List entries for that agency's tags |
| `charges_{agencyA}_{agencyB}` | Agency A + Agency B only | Charge, Correction, Reconciliation, Settlement records between the pair |
| `hub_aggregate_{hubID}` | Hub + its member agencies | Aggregated reporting data for hub-routed transactions |

#### How Transactions Flow on the Ledger

```
DIRECT (Agency A → Agency B):
  Agency A's peer writes Charge to private collection charges_A_B
  Agency B's peer reads, posts, writes Reconciliation
  Both agencies operate their own Fabric infrastructure

HUB-ROUTED (Agency A via Hub X → Agency B):
  Agency A sends charge data to Hub X's API
  Hub X's peer writes Charge to private collection charges_hubX_B
  Agency B reads, posts, writes Reconciliation
  Hub X maintains aggregate reporting in hub_aggregate_hubX
  From Agency B's perspective, the charge came from Hub X (submittedVia = hubX)

CROSS-CONSORTIUM (Agency A in CUSIOP → Agency B in E-ZPass):
  Same as above — either direct or hub-routed
  Both paths produce the same Charge record on the interop channel
  Consortium channels handle governance; the interop channel handles data
```

#### Why This Works for Adoption

- **Day 1:** Two agencies (e.g., TCA and NTTA) join in direct mode and start transacting. No hub needed.
- **Early growth:** A hub (e.g., CUSIOP) joins and operates peers for member agencies that aren't ready to run their own Fabric infrastructure. The hub acts as a managed service provider.
- **Migration:** Individual agencies can move from hub-routed to direct mode at their own pace. They stand up their own peers, get their own CA, and start submitting directly. The hub remains on the consortium governance channel but stops routing that agency's transactions.
- **Full scale:** All four consortiums and their member agencies are on the network. Cross-consortium transactions that used to take days via SFTP now settle in near-real-time on the `interop` channel.

---

## 3. Roadmap

*What do we build, in what order, and what does each milestone deliver?*

- Phase 1: Foundation (chaincode, local dev environment, basic API)
- Phase 2: Network (multi-org deployment, identity management, private data)
- Phase 3: Integration (agency onboarding, NIOP/CTOC protocol compliance)
- Phase 4: Production (GKE deployment, monitoring, security hardening)
- Phase 5: Scale (additional agencies, analytics, reporting)

---

## 4. Network Participants & Governance

*Who are the organizations in the network, and how do they make decisions?*

- Founding members vs. future participants
- Org roles (toll operator, clearinghouse, regulator)
- Channel and consortium structure
- Governance model — who approves chaincode upgrades, new members, policy changes
- Ordering service ownership and operation

---

## 5. Privacy Model

*What data is visible to whom? How do we enforce data isolation between agencies?*

- Private data collections design
- Channel strategy (single channel vs. per-relationship channels)
- Data classification (public, org-private, bilateral)
- Encryption requirements — what must be encrypted at rest and in transit
- Compliance with toll industry data-sharing agreements

---

## 6. Integration Points

*How does Tolling.Network connect to existing agency systems?*

- Inbound: toll event ingestion (real-time vs. batch)
- Outbound: settlement and reconciliation data export
- NIOP protocol interface — message formats, transport
- CTOC protocol interface — California-specific requirements
- IAG/E-ZPass compatibility
- Agency back-office system integration patterns

---

## 7. Business Model

*How does the network sustain itself?*

- Who pays for infrastructure
- Fee structure (per-transaction, subscription, hybrid)
- Open source strategy — what's open, what's proprietary
- Competitive positioning against existing clearinghouses
- Go-to-market approach

---

## 8. Regulatory & Compliance

*What legal and regulatory requirements apply?*

- Federal toll interoperability mandates
- State-specific regulations (California, Texas, etc.)
- Data retention requirements
- PII handling and privacy laws
- Audit and reporting obligations
- Contractual requirements between agencies
