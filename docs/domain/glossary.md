# Tolling Network Glossary

This glossary defines terminology used throughout the Tolling Network codebase and documentation.

## Agencies and Roles

### Agency
An organization that participates in the tolling network. Agencies can have multiple roles.

### Away Agency
The agency that operates the toll facility where a transaction occurred. The away agency sends charges to the home agency for payment. Also called the "toll operator" in some contexts.

### Home Agency
The agency that issued the transponder (tag) used in a transaction. The home agency is responsible for collecting payment from the customer and remitting funds to the away agency.

### Toll Operator
An agency role indicating the organization operates toll facilities (roads, bridges, tunnels).

### Tag Issuer
An agency role indicating the organization issues transponders to customers.

### Consortium
A regional grouping of agencies that have agreed to interoperability standards. Examples: WRTO (Western Region Toll Operators).

## Transponders and Tags

### Tag / Transponder
An electronic device (typically RFID) mounted in a vehicle that identifies the account for toll collection. Terms are used interchangeably.

### Tag Serial Number
A unique identifier for a transponder, following the format `AGENCY.SERIAL` (e.g., `TCA.000000001`).

### Tag Status
The current state of a transponder:
- **valid**: Tag is active and can be used for toll payment
- **invalid**: Tag has been deactivated (e.g., account closed)
- **inactive**: Tag is temporarily suspended
- **lost**: Customer reported the tag as lost
- **stolen**: Customer reported the tag as stolen

### Tag Type
The billing arrangement for a transponder:
- **single**: One vehicle per account
- **loaded**: Prepaid balance on the tag
- **flex**: Flexible payment arrangements
- **generic**: General-purpose tag

### Tag Protocol
The radio frequency protocol used by the transponder:
- **sego**: SeGo protocol
- **6c**: Title 21/6C protocol
- **tdm**: Time Division Multiplexing

## Transactions

### Charge
A toll transaction where a vehicle with an away agency's tag used a home agency's facility. Charges flow from away agency to home agency.

### Charge Type
- **toll_tag**: Standard transponder-based toll
- **video**: License plate-based toll (image capture)

### Record Type
NIOP standard record type codes:
- **TB01**: Tag-based transaction
- **VB01**: Video-based transaction
- **TB01A/VB01A**: Adjustment (correction) records

### Charge Status
The lifecycle state of a charge:
- **pending**: Charge created, awaiting processing
- **posted**: Charge posted to customer account
- **rejected**: Charge rejected (invalid tag, etc.)
- **disputed**: Customer disputed the charge
- **settled**: Charge included in settlement

## Reconciliation and Settlement

### Reconciliation
The process of matching charges between agencies and confirming posting status.

### Posting Disposition
The result of attempting to post a charge to a customer account:
- **P**: Posted successfully
- **U**: Unpostable (account issue)
- **D**: Duplicate transaction
- **I**: Invalid tag
- **X**: Expired tag

### Settlement
A periodic financial reconciliation between two agencies, summarizing charges and determining net payment.

### Settlement Status
- **draft**: Settlement being prepared
- **submitted**: Settlement sent for review
- **accepted**: Counterparty accepted the settlement
- **disputed**: Counterparty disputed amounts
- **paid**: Payment completed
- **cancelled**: Settlement cancelled

### Payor Agency
In a settlement, the agency that owes money (net debtor).

### Payee Agency
In a settlement, the agency that is owed money (net creditor).

## Corrections

### Correction
An adjustment to a previously submitted charge. Corrections reference the original charge.

### Correction Reason
- **C**: Charge correction (amount adjustment)
- **D**: Deletion (void the original charge)
- **R**: Replacement (supersede original)

### Correction Sequence Number
A counter (1-999) tracking multiple corrections to the same original charge.

## Acknowledgements

### Acknowledgement
A response from the receiving agency confirming receipt and processing status of a batch submission.

### Submission Type
The type of batch being acknowledged:
- **TAGFILE**: Tag status file
- **ITAG**: Individual tag update
- **ICTX**: Individual charge transaction
- **ICTXACK**: Charge acknowledgement
- **IRECON**: Reconciliation file

### Return Code
Two-digit code indicating acknowledgement result:
- **00**: Accepted, no errors
- **01-13**: Various error conditions (see NIOP spec)

## Protocols and Standards

### NIOP
National Interoperability Protocol - the standard for toll interoperability data exchange.

### CTOC
California Toll Operators Committee - regional interoperability standard (predecessor to NIOP in California).

### Protocol Support
The data exchange protocols an agency supports (e.g., `niop`, `ctoc_rev_a`).

## Technical Terms

### World State
Hyperledger Fabric's current state database, containing the latest version of all key-value pairs.

### Private Data Collection
A Fabric feature allowing confidential data to be shared only between authorized organizations.

### Bilateral Collection
A private data collection shared between exactly two agencies, named using alphabetical sorting (e.g., `charges_BATA_TCA`).

### DocType
A field in each document indicating its type (e.g., `tag`, `charge`, `settlement`), used for CouchDB indexing.

### Rich Query
A CouchDB query using JSON selectors to find documents by field values, as opposed to key-based lookups.
