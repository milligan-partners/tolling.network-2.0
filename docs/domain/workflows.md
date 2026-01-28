# Tolling Network Workflows

This document describes the key business processes implemented in the Tolling Network chaincode.

## Tag Lifecycle

```
                    ┌─────────┐
                    │  valid  │◄──────────────────┐
                    └────┬────┘                   │
                         │                        │
         ┌───────────────┼───────────────┐        │
         ▼               ▼               ▼        │
    ┌─────────┐    ┌──────────┐    ┌─────────┐   │
    │ invalid │    │ inactive │    │  lost   │───┤
    └─────────┘    └──────────┘    └─────────┘   │
         ▲               │               │        │
         │               │               │        │
         └───────────────┴───────────────┘        │
                         │                        │
                         ▼                        │
                    ┌─────────┐                   │
                    │ stolen  │───────────────────┘
                    └─────────┘
```

### States

| Status | Description | Allowed Transitions |
|--------|-------------|---------------------|
| valid | Tag is active for toll payment | invalid, inactive, lost, stolen |
| invalid | Tag permanently deactivated | valid (reactivation) |
| inactive | Tag temporarily suspended | valid, invalid |
| lost | Customer reported tag lost | valid, invalid |
| stolen | Customer reported tag stolen | valid, invalid |

### Triggers

- **valid → invalid**: Account closure, tag returned
- **valid → inactive**: Payment issue, temporary suspension
- **valid → lost/stolen**: Customer report
- **lost/stolen → valid**: Tag recovered
- **inactive → valid**: Payment resolved

## Charge Processing Flow

```
Away Agency                          Home Agency
    │                                     │
    │  1. Vehicle uses toll facility      │
    │                                     │
    │  2. CreateCharge (pending)          │
    ├────────────────────────────────────►│
    │                                     │
    │                                     │  3. Validate tag
    │                                     │  4. Post to account
    │                                     │
    │  5. CreateReconciliation            │
    │◄────────────────────────────────────┤
    │     (disposition: P/U/D/I/X)        │
    │                                     │
    │  6. UpdateChargeStatus              │
    │     (posted/rejected)               │
    │                                     │
```

### Charge Status Transitions

```
pending ──► posted ──► settled
    │
    └─────► rejected
```

## Settlement Process

```
┌─────────────────────────────────────────────────────────┐
│                    Settlement Lifecycle                  │
└─────────────────────────────────────────────────────────┘

   Payor Agency                           Payee Agency
        │                                      │
        │  1. CreateSettlement (draft)         │
        ├─────────────────────────────────────►│
        │                                      │
        │  2. Review charges included          │
        │                                      │
        │  3. UpdateStatus (submitted)         │
        ├─────────────────────────────────────►│
        │                                      │
        │                              4. Review settlement
        │                                      │
        │         5a. UpdateStatus (accepted)  │
        │◄─────────────────────────────────────┤
        │                  OR                  │
        │         5b. UpdateStatus (disputed)  │
        │◄─────────────────────────────────────┤
        │                                      │
        │  6. If accepted: Make payment        │
        │                                      │
        │  7. UpdateStatus (paid)              │
        ├─────────────────────────────────────►│
        │                                      │
```

### Settlement Status Transitions

```
draft ──► submitted ──► accepted ──► paid
              │
              └───────► disputed ──► [resolution] ──► accepted
                            │
                            └───────────────────────► cancelled
```

## Correction Flow

Corrections adjust previously submitted charges.

```
Original Charge                    Correction
      │                                 │
      │                                 │
      ▼                                 ▼
┌───────────┐                    ┌───────────────┐
│ CHG-001   │◄───────────────────│ CHG-001_001   │
│ Amount:   │    references      │ Reason: C     │
│ $4.75     │                    │ Amount: $3.50 │
└───────────┘                    └───────────────┘
                                        │
                                        ▼
                                 ┌───────────────┐
                                 │ CHG-001_002   │
                                 │ Reason: C     │
                                 │ Amount: $4.00 │
                                 └───────────────┘
```

### Correction Reasons

| Code | Meaning | Effect |
|------|---------|--------|
| C | Correction | Adjusts amount |
| D | Deletion | Voids original charge |
| R | Replacement | Supersedes original |

## Acknowledgement Flow

Acknowledges receipt and processing of batch submissions.

```
Sending Agency                     Receiving Agency
      │                                  │
      │  1. Send batch (TAGFILE, etc.)   │
      ├─────────────────────────────────►│
      │                                  │
      │                           2. Process batch
      │                           3. CreateAcknowledgement
      │                                  │
      │  4. Acknowledgement returned     │
      │◄─────────────────────────────────┤
      │     (returnCode: 00-13)          │
      │                                  │
```

### Return Codes

| Code | Meaning |
|------|---------|
| 00 | Accepted, no errors |
| 01-13 | Various error conditions (see NIOP spec) |
