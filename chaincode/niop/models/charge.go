// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"fmt"
	"time"
)

// Charge represents a toll or mobility charge generated when a vehicle uses
// a facility. This is the central transaction entity.
type Charge struct {
	ChargeID        string  `json:"chargeID"`
	ChargeType      string  `json:"chargeType"`
	RecordType      string  `json:"recordType"`
	Protocol        string  `json:"protocol"`
	AwayAgencyID    string  `json:"awayAgencyID"`
	HomeAgencyID    string  `json:"homeAgencyID"`
	SubmittedVia    string  `json:"submittedVia,omitempty"`
	TagSerialNumber string  `json:"tagSerialNumber,omitempty"`
	PlateCountry    string  `json:"plateCountry,omitempty"`
	PlateState      string  `json:"plateState,omitempty"`
	PlateNumber     string  `json:"plateNumber,omitempty"`
	FacilityID      string  `json:"facilityID"`
	Plaza           string  `json:"plaza,omitempty"`
	Lane            string  `json:"lane,omitempty"`
	EntryPlaza      string  `json:"entryPlaza,omitempty"`
	EntryDateTime   string  `json:"entryDateTime,omitempty"`
	ExitDateTime    string  `json:"exitDateTime"`
	VehicleClass    int     `json:"vehicleClass"`
	Occupancy       int     `json:"occupancy,omitempty"`
	Amount          float64 `json:"amount"`
	Fee             float64 `json:"fee"`
	NetAmount       float64 `json:"netAmount"`
	DiscountPlan    string  `json:"discountPlanType,omitempty"`
	Status          string  `json:"status"`
	CreatedAt       string  `json:"createdAt"`
}

// Valid charge types.
var ValidChargeTypes = []string{
	"toll_tag", "toll_video", "toll_paybyplate",
	"congestion", "parking", "transit",
}

// Valid NIOP record types for charges.
var ValidRecordTypes = []string{"TB01", "TC01", "TC02", "VB01", "VC01", "VC02"}

// Valid protocols.
var ValidChargeProtocols = []string{"niop", "iag", "ctoc", "native"}

// Valid charge statuses.
var ValidChargeStatuses = []string{"pending", "posted", "disputed", "rejected", "settled"}

// Tag-based record types (require tag serial number).
var tagBasedRecordTypes = []string{"TB01", "TC01", "TC02"}

// Video/plate-based record types (require plate info).
var videoBasedRecordTypes = []string{"VB01", "VC01", "VC02"}

// Validate checks all fields of a Charge and returns an error describing
// the first validation failure, or nil if the charge is valid.
func (c *Charge) Validate() error {
	if c.ChargeID == "" {
		return fmt.Errorf("chargeID is required")
	}
	if c.ChargeType == "" {
		return fmt.Errorf("chargeType is required")
	}
	if !contains(ValidChargeTypes, c.ChargeType) {
		return fmt.Errorf("invalid chargeType %q: must be one of %v", c.ChargeType, ValidChargeTypes)
	}
	if c.RecordType == "" {
		return fmt.Errorf("recordType is required")
	}
	if !contains(ValidRecordTypes, c.RecordType) {
		return fmt.Errorf("invalid recordType %q: must be one of %v", c.RecordType, ValidRecordTypes)
	}
	if c.Protocol == "" {
		return fmt.Errorf("protocol is required")
	}
	if !contains(ValidChargeProtocols, c.Protocol) {
		return fmt.Errorf("invalid protocol %q: must be one of %v", c.Protocol, ValidChargeProtocols)
	}
	if c.AwayAgencyID == "" {
		return fmt.Errorf("awayAgencyID is required")
	}
	if c.HomeAgencyID == "" {
		return fmt.Errorf("homeAgencyID is required")
	}
	if c.AwayAgencyID == c.HomeAgencyID {
		return fmt.Errorf("awayAgencyID and homeAgencyID must be different")
	}
	if c.FacilityID == "" {
		return fmt.Errorf("facilityID is required")
	}
	if c.ExitDateTime == "" {
		return fmt.Errorf("exitDateTime is required")
	}
	if c.VehicleClass < 1 {
		return fmt.Errorf("vehicleClass must be >= 1, got %d", c.VehicleClass)
	}
	if c.Amount < 0 {
		return fmt.Errorf("amount must be >= 0, got %f", c.Amount)
	}
	if c.Fee < 0 {
		return fmt.Errorf("fee must be >= 0, got %f", c.Fee)
	}
	if c.NetAmount < 0 {
		return fmt.Errorf("netAmount must be >= 0, got %f", c.NetAmount)
	}
	if c.Status == "" {
		return fmt.Errorf("status is required")
	}
	if !contains(ValidChargeStatuses, c.Status) {
		return fmt.Errorf("invalid status %q: must be one of %v", c.Status, ValidChargeStatuses)
	}

	// Tag-based charges require a tag serial number.
	if contains(tagBasedRecordTypes, c.RecordType) && c.TagSerialNumber == "" {
		return fmt.Errorf("tagSerialNumber is required for tag-based record type %s", c.RecordType)
	}

	// Video-based charges require plate information.
	if contains(videoBasedRecordTypes, c.RecordType) {
		if c.PlateNumber == "" {
			return fmt.Errorf("plateNumber is required for video-based record type %s", c.RecordType)
		}
		if c.PlateState == "" {
			return fmt.Errorf("plateState is required for video-based record type %s", c.RecordType)
		}
	}

	return nil
}

// ValidateStatusTransition checks whether a charge status change is allowed.
// Valid transitions:
//   - pending -> posted, rejected
//   - posted -> disputed, settled
//   - disputed -> posted, settled
//   - rejected -> pending (resubmission)
func (c *Charge) ValidateStatusTransition(newStatus string) error {
	if !contains(ValidChargeStatuses, newStatus) {
		return fmt.Errorf("invalid target status %q: must be one of %v", newStatus, ValidChargeStatuses)
	}
	if c.Status == newStatus {
		return fmt.Errorf("charge is already in status %q", newStatus)
	}

	allowed := map[string][]string{
		"pending":  {"posted", "rejected"},
		"posted":   {"disputed", "settled"},
		"disputed": {"posted", "settled"},
		"rejected": {"pending"},
	}

	transitions, ok := allowed[c.Status]
	if !ok {
		return fmt.Errorf("no transitions allowed from status %q", c.Status)
	}
	if !contains(transitions, newStatus) {
		return fmt.Errorf("cannot transition charge from %q to %q", c.Status, newStatus)
	}
	return nil
}

// Key returns the ledger key for this charge.
func (c *Charge) Key() string {
	return "CHARGE_" + c.ChargeID
}

// SetCreatedAt sets CreatedAt to the current time.
func (c *Charge) SetCreatedAt() {
	c.CreatedAt = time.Now().UTC().Format(time.RFC3339)
}

// CollectionName returns the private data collection name for this charge.
// Charges are stored in bilateral collections between away and home agency.
func (c *Charge) CollectionName() string {
	a, b := c.AwayAgencyID, c.HomeAgencyID
	if a > b {
		a, b = b, a
	}
	return "charges_" + a + "_" + b
}
