// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"fmt"
	"time"
)

// Settlement represents a financial settlement between two agencies for
// a reconciliation period. This aggregates reconciled charges into a net
// amount owed.
type Settlement struct {
	SettlementID    string  `json:"settlementID"`
	PeriodStart     string  `json:"periodStart"`
	PeriodEnd       string  `json:"periodEnd"`
	PayorAgencyID   string  `json:"payorAgencyID"`
	PayeeAgencyID   string  `json:"payeeAgencyID"`
	GrossAmount     float64 `json:"grossAmount"`
	TotalFees       float64 `json:"totalFees"`
	NetAmount       float64 `json:"netAmount"`
	ChargeCount     int     `json:"chargeCount"`
	CorrectionCount int     `json:"correctionCount"`
	Status          string  `json:"status"`
	CreatedAt       string  `json:"createdAt"`
}

// Valid settlement statuses.
var ValidSettlementStatuses = []string{"draft", "submitted", "accepted", "disputed", "paid"}

// Validate checks all fields of a Settlement and returns an error
// describing the first validation failure, or nil if valid.
func (s *Settlement) Validate() error {
	if s.SettlementID == "" {
		return fmt.Errorf("settlementID is required")
	}
	if s.PeriodStart == "" {
		return fmt.Errorf("periodStart is required")
	}
	if s.PeriodEnd == "" {
		return fmt.Errorf("periodEnd is required")
	}
	if s.PeriodEnd < s.PeriodStart {
		return fmt.Errorf("periodEnd %q must not be before periodStart %q", s.PeriodEnd, s.PeriodStart)
	}
	if s.PayorAgencyID == "" {
		return fmt.Errorf("payorAgencyID is required")
	}
	if s.PayeeAgencyID == "" {
		return fmt.Errorf("payeeAgencyID is required")
	}
	if s.PayorAgencyID == s.PayeeAgencyID {
		return fmt.Errorf("payorAgencyID and payeeAgencyID must be different")
	}
	if s.GrossAmount < 0 {
		return fmt.Errorf("grossAmount must be >= 0, got %f", s.GrossAmount)
	}
	if s.TotalFees < 0 {
		return fmt.Errorf("totalFees must be >= 0, got %f", s.TotalFees)
	}
	if s.NetAmount < 0 {
		return fmt.Errorf("netAmount must be >= 0, got %f", s.NetAmount)
	}
	if s.ChargeCount < 0 {
		return fmt.Errorf("chargeCount must be >= 0, got %d", s.ChargeCount)
	}
	if s.CorrectionCount < 0 {
		return fmt.Errorf("correctionCount must be >= 0, got %d", s.CorrectionCount)
	}
	if s.Status == "" {
		return fmt.Errorf("status is required")
	}
	if !contains(ValidSettlementStatuses, s.Status) {
		return fmt.Errorf("invalid status %q: must be one of %v", s.Status, ValidSettlementStatuses)
	}
	return nil
}

// ValidateStatusTransition checks whether a settlement status change is allowed.
// Valid transitions:
//   - draft -> submitted
//   - submitted -> accepted, disputed
//   - accepted -> paid
//   - disputed -> submitted, accepted
func (s *Settlement) ValidateStatusTransition(newStatus string) error {
	if !contains(ValidSettlementStatuses, newStatus) {
		return fmt.Errorf("invalid target status %q: must be one of %v", newStatus, ValidSettlementStatuses)
	}
	if s.Status == newStatus {
		return fmt.Errorf("settlement is already in status %q", newStatus)
	}

	allowed := map[string][]string{
		"draft":    {"submitted"},
		"submitted": {"accepted", "disputed"},
		"accepted":  {"paid"},
		"disputed":  {"submitted", "accepted"},
	}

	transitions, ok := allowed[s.Status]
	if !ok {
		return fmt.Errorf("no transitions allowed from status %q", s.Status)
	}
	if !contains(transitions, newStatus) {
		return fmt.Errorf("cannot transition settlement from %q to %q", s.Status, newStatus)
	}
	return nil
}

// Key returns the ledger key for this settlement.
func (s *Settlement) Key() string {
	return "SETTLEMENT_" + s.SettlementID
}

// SetCreatedAt sets CreatedAt to the current time.
func (s *Settlement) SetCreatedAt() {
	s.CreatedAt = time.Now().UTC().Format(time.RFC3339)
}

// CollectionName returns the private data collection name for this settlement.
// Settlements are stored in bilateral collections.
func (s *Settlement) CollectionName() string {
	a, b := s.PayorAgencyID, s.PayeeAgencyID
	if a > b {
		a, b = b, a
	}
	return "charges_" + a + "_" + b
}
