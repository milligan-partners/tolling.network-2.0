// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"fmt"
	"time"
)

// Correction represents an adjustment to a previously submitted charge.
// Corrections maintain a full audit trail via sequence numbers.
type Correction struct {
	DocType          string  `json:"docType"`
	CorrectionID     string  `json:"correctionID"`
	OriginalChargeID string  `json:"originalChargeID"`
	CorrectionSeqNo  int     `json:"correctionSeqNo"`
	CorrectionReason string  `json:"correctionReason"`
	ResubmitReason   string  `json:"resubmitReason,omitempty"`
	ResubmitCount    int     `json:"resubmitCount,omitempty"`
	FromAgencyID     string  `json:"fromAgencyID"`
	ToAgencyID       string  `json:"toAgencyID"`
	RecordType       string  `json:"recordType"`
	Amount           float64 `json:"amount"`
	CreatedAt        string  `json:"createdAt"`
}

// Valid correction reason codes.
var ValidCorrectionReasons = []string{"C", "I", "L", "T", "O"}

// CorrectionReasonDescriptions maps codes to human-readable descriptions.
var CorrectionReasonDescriptions = map[string]string{
	"C": "Correction",
	"I": "Invalid",
	"L": "Late",
	"T": "Technical",
	"O": "Other",
}

// Valid resubmit reason codes.
var ValidResubmitReasons = []string{"R", "S"}

// Valid correction record types (original type with 'A' suffix).
var ValidCorrectionRecordTypes = []string{
	"TB01A", "TC01A", "TC02A", "VB01A", "VC01A", "VC02A",
}

// Validate checks all fields of a Correction and returns an error describing
// the first validation failure, or nil if the correction is valid.
func (c *Correction) Validate() error {
	if c.CorrectionID == "" {
		return fmt.Errorf("correctionID is required")
	}
	if c.OriginalChargeID == "" {
		return fmt.Errorf("originalChargeID is required")
	}
	if c.CorrectionSeqNo < 0 || c.CorrectionSeqNo > 999 {
		return fmt.Errorf("correctionSeqNo must be between 0 and 999, got %d", c.CorrectionSeqNo)
	}
	if c.CorrectionReason == "" {
		return fmt.Errorf("correctionReason is required")
	}
	if !contains(ValidCorrectionReasons, c.CorrectionReason) {
		return fmt.Errorf("invalid correctionReason %q: must be one of %v", c.CorrectionReason, ValidCorrectionReasons)
	}
	if c.ResubmitReason != "" && !contains(ValidResubmitReasons, c.ResubmitReason) {
		return fmt.Errorf("invalid resubmitReason %q: must be one of %v", c.ResubmitReason, ValidResubmitReasons)
	}
	if c.FromAgencyID == "" {
		return fmt.Errorf("fromAgencyID is required")
	}
	if c.ToAgencyID == "" {
		return fmt.Errorf("toAgencyID is required")
	}
	if c.FromAgencyID == c.ToAgencyID {
		return fmt.Errorf("fromAgencyID and toAgencyID must be different")
	}
	if c.RecordType == "" {
		return fmt.Errorf("recordType is required")
	}
	if !contains(ValidCorrectionRecordTypes, c.RecordType) {
		return fmt.Errorf("invalid correction recordType %q: must be one of %v (original type with A suffix)", c.RecordType, ValidCorrectionRecordTypes)
	}
	if c.Amount < 0 {
		return fmt.Errorf("amount must be >= 0, got %f", c.Amount)
	}
	return nil
}

// Key returns the ledger key for this correction.
func (c *Correction) Key() string {
	return fmt.Sprintf("CORRECTION_%s_%03d", c.OriginalChargeID, c.CorrectionSeqNo)
}

// SetCreatedAt sets CreatedAt to the current time and ensures DocType is set.
func (c *Correction) SetCreatedAt() {
	c.DocType = "correction"
	c.CreatedAt = time.Now().UTC().Format(time.RFC3339)
}

// CollectionName returns the private data collection name for this correction.
// Corrections are stored in the same bilateral collection as charges.
func (c *Correction) CollectionName() string {
	a, b := c.FromAgencyID, c.ToAgencyID
	if a > b {
		a, b = b, a
	}
	return "charges_" + a + "_" + b
}
