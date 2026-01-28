// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"fmt"
	"time"
)

// Reconciliation represents the home agency's response to a submitted charge.
// It records whether the charge was posted and any adjustments made.
type Reconciliation struct {
	ReconciliationID   string  `json:"reconciliationID"`
	ChargeID           string  `json:"chargeID"`
	HomeAgencyID       string  `json:"homeAgencyID"`
	PostingDisposition string  `json:"postingDisposition"`
	PostedAmount       float64 `json:"postedAmount"`
	PostedDateTime     string  `json:"postedDateTime,omitempty"`
	AdjustmentCount    int     `json:"adjustmentCount"`
	ResubmitCount      int     `json:"resubmitCount,omitempty"`
	FlatFee            float64 `json:"flatFee"`
	PercentFee         float64 `json:"percentFee"`
	DiscountPlanType   string  `json:"discountPlanType,omitempty"`
	CreatedAt          string  `json:"createdAt"`
}

// Valid posting disposition codes.
var ValidPostingDispositions = []string{"P", "D", "I", "N", "S", "T", "C", "O"}

// PostingDispositionDescriptions maps codes to human-readable descriptions.
var PostingDispositionDescriptions = map[string]string{
	"P": "Posted successfully",
	"D": "Duplicate transaction",
	"I": "Invalid tag or plate",
	"N": "Not posted (general)",
	"S": "System or communication issue",
	"T": "Transaction content/format error",
	"C": "Tag/plate not on file",
	"O": "Transaction too old",
}

// Validate checks all fields of a Reconciliation and returns an error
// describing the first validation failure, or nil if valid.
func (r *Reconciliation) Validate() error {
	if r.ReconciliationID == "" {
		return fmt.Errorf("reconciliationID is required")
	}
	if r.ChargeID == "" {
		return fmt.Errorf("chargeID is required")
	}
	if r.HomeAgencyID == "" {
		return fmt.Errorf("homeAgencyID is required")
	}
	if r.PostingDisposition == "" {
		return fmt.Errorf("postingDisposition is required")
	}
	if !contains(ValidPostingDispositions, r.PostingDisposition) {
		return fmt.Errorf("invalid postingDisposition %q: must be one of %v", r.PostingDisposition, ValidPostingDispositions)
	}
	if r.PostedAmount < 0 {
		return fmt.Errorf("postedAmount must be >= 0, got %f", r.PostedAmount)
	}
	if r.AdjustmentCount < 0 {
		return fmt.Errorf("adjustmentCount must be >= 0, got %d", r.AdjustmentCount)
	}
	if r.FlatFee < 0 {
		return fmt.Errorf("flatFee must be >= 0, got %f", r.FlatFee)
	}
	if r.PercentFee < 0 {
		return fmt.Errorf("percentFee must be >= 0, got %f", r.PercentFee)
	}

	// Posted disposition requires a posted date/time.
	if r.PostingDisposition == "P" && r.PostedDateTime == "" {
		return fmt.Errorf("postedDateTime is required when postingDisposition is P")
	}

	return nil
}

// Key returns the ledger key for this reconciliation.
func (r *Reconciliation) Key() string {
	return "RECON_" + r.ChargeID
}

// SetCreatedAt sets CreatedAt to the current time.
func (r *Reconciliation) SetCreatedAt() {
	r.CreatedAt = time.Now().UTC().Format(time.RFC3339)
}

// IsPosted returns true if the charge was successfully posted.
func (r *Reconciliation) IsPosted() bool {
	return r.PostingDisposition == "P"
}
