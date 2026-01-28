// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"fmt"
	"time"
)

// Acknowledgement represents a protocol-level response confirming receipt
// and validation of a data submission (TVL, transaction batch, correction
// batch, or reconciliation batch).
type Acknowledgement struct {
	AcknowledgementID string `json:"acknowledgementID"`
	SubmissionType    string `json:"submissionType"`
	FromAgencyID      string `json:"fromAgencyID"`
	ToAgencyID        string `json:"toAgencyID"`
	ReturnCode        string `json:"returnCode"`
	ReturnMessage     string `json:"returnMessage,omitempty"`
	CreatedAt         string `json:"createdAt"`
}

// Valid submission types.
var ValidSubmissionTypes = []string{"STVL", "STRAN", "SCORR", "SRECON"}

// SubmissionTypeDescriptions maps codes to descriptions.
var SubmissionTypeDescriptions = map[string]string{
	"STVL":   "Tag Validation List",
	"STRAN":  "Transaction Data",
	"SCORR":  "Correction Data",
	"SRECON": "Reconciliation Data",
}

// Valid acknowledgement return codes (00-13).
var ValidReturnCodes = []string{
	"00", "01", "02", "03", "04", "05", "06",
	"07", "08", "09", "10", "11", "12", "13",
}

// ReturnCodeDescriptions maps return codes to human-readable descriptions.
var ReturnCodeDescriptions = map[string]string{
	"00": "Success",
	"01": "Invalid submission type",
	"02": "Invalid agency ID",
	"03": "Sequence number error",
	"04": "Record count mismatch",
	"05": "Duplicate submission",
	"06": "Format error",
	"07": "System error",
	"08": "Unauthorized",
	"09": "Invalid date range",
	"10": "File too large",
	"11": "Partial acceptance",
	"12": "Rejected",
	"13": "Unknown error",
}

// Validate checks all fields of an Acknowledgement and returns an error
// describing the first validation failure, or nil if valid.
func (a *Acknowledgement) Validate() error {
	if a.AcknowledgementID == "" {
		return fmt.Errorf("acknowledgementID is required")
	}
	if a.SubmissionType == "" {
		return fmt.Errorf("submissionType is required")
	}
	if !contains(ValidSubmissionTypes, a.SubmissionType) {
		return fmt.Errorf("invalid submissionType %q: must be one of %v", a.SubmissionType, ValidSubmissionTypes)
	}
	if a.FromAgencyID == "" {
		return fmt.Errorf("fromAgencyID is required")
	}
	if a.ToAgencyID == "" {
		return fmt.Errorf("toAgencyID is required")
	}
	if a.ReturnCode == "" {
		return fmt.Errorf("returnCode is required")
	}
	if !contains(ValidReturnCodes, a.ReturnCode) {
		return fmt.Errorf("invalid returnCode %q: must be one of 00-13", a.ReturnCode)
	}
	return nil
}

// Key returns the ledger key for this acknowledgement.
func (a *Acknowledgement) Key() string {
	return "ACK_" + a.AcknowledgementID
}

// SetCreatedAt sets CreatedAt to the current time.
func (a *Acknowledgement) SetCreatedAt() {
	a.CreatedAt = time.Now().UTC().Format(time.RFC3339)
}

// IsSuccess returns true if the return code indicates success.
func (a *Acknowledgement) IsSuccess() bool {
	return a.ReturnCode == "00"
}
