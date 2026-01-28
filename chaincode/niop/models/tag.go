// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"fmt"
	"time"
)

// DiscountPlan represents a discount plan associated with a tag.
type DiscountPlan struct {
	Type      string `json:"type"`
	StartDate string `json:"startDate"`
	EndDate   string `json:"endDate,omitempty"`
}

// Plate represents a license plate associated with a tag.
type Plate struct {
	Country       string `json:"country"`
	State         string `json:"state"`
	Number        string `json:"number"`
	Type          string `json:"type,omitempty"`
	EffectiveDate string `json:"effectiveDate,omitempty"`
	EndDate       string `json:"endDate,omitempty"`
}

// Tag represents a transponder or device associated with an account.
// Tags are the primary identifier for electronic toll collection.
type Tag struct {
	TagSerialNumber string         `json:"tagSerialNumber"`
	TagAgencyID     string         `json:"tagAgencyID"`
	HomeAgencyID    string         `json:"homeAgencyID"`
	AccountID       string         `json:"accountID"`
	TagStatus       string         `json:"tagStatus"`
	TagType         string         `json:"tagType"`
	TagClass        int            `json:"tagClass"`
	TagProtocol     string         `json:"tagProtocol"`
	DiscountPlans   []DiscountPlan `json:"discountPlans,omitempty"`
	Plates          []Plate        `json:"plates,omitempty"`
	UpdatedAt       string         `json:"updatedAt"`
}

// Valid tag statuses.
var ValidTagStatuses = []string{"valid", "invalid", "inactive", "lost", "stolen"}

// Valid tag types.
var ValidTagTypes = []string{"single", "loaded", "flex", "generic"}

// Valid tag protocols.
var ValidTagProtocols = []string{"sego", "6c", "tdm"}

// Validate checks all fields of a Tag and returns an error describing
// the first validation failure, or nil if the tag is valid.
func (t *Tag) Validate() error {
	if t.TagSerialNumber == "" {
		return fmt.Errorf("tagSerialNumber is required")
	}
	if t.TagAgencyID == "" {
		return fmt.Errorf("tagAgencyID is required")
	}
	if t.HomeAgencyID == "" {
		return fmt.Errorf("homeAgencyID is required")
	}
	if t.AccountID == "" {
		return fmt.Errorf("accountID is required")
	}
	if t.TagStatus == "" {
		return fmt.Errorf("tagStatus is required")
	}
	if !contains(ValidTagStatuses, t.TagStatus) {
		return fmt.Errorf("invalid tagStatus %q: must be one of %v", t.TagStatus, ValidTagStatuses)
	}
	if t.TagType == "" {
		return fmt.Errorf("tagType is required")
	}
	if !contains(ValidTagTypes, t.TagType) {
		return fmt.Errorf("invalid tagType %q: must be one of %v", t.TagType, ValidTagTypes)
	}
	if t.TagClass < 1 {
		return fmt.Errorf("tagClass must be >= 1, got %d", t.TagClass)
	}
	if t.TagProtocol == "" {
		return fmt.Errorf("tagProtocol is required")
	}
	if !contains(ValidTagProtocols, t.TagProtocol) {
		return fmt.Errorf("invalid tagProtocol %q: must be one of %v", t.TagProtocol, ValidTagProtocols)
	}
	return nil
}

// ValidateStatusTransition checks whether a status change is allowed.
// Valid transitions:
//   - valid -> invalid, inactive, lost, stolen
//   - invalid -> valid
//   - inactive -> valid, invalid
//   - lost -> valid, invalid
//   - stolen -> valid, invalid
func (t *Tag) ValidateStatusTransition(newStatus string) error {
	if !contains(ValidTagStatuses, newStatus) {
		return fmt.Errorf("invalid target tagStatus %q: must be one of %v", newStatus, ValidTagStatuses)
	}
	if t.TagStatus == newStatus {
		return fmt.Errorf("tag is already in status %q", newStatus)
	}

	allowed := map[string][]string{
		"valid":    {"invalid", "inactive", "lost", "stolen"},
		"invalid":  {"valid"},
		"inactive": {"valid", "invalid"},
		"lost":     {"valid", "invalid"},
		"stolen":   {"valid", "invalid"},
	}

	transitions, ok := allowed[t.TagStatus]
	if !ok {
		return fmt.Errorf("unknown current status %q", t.TagStatus)
	}
	if !contains(transitions, newStatus) {
		return fmt.Errorf("cannot transition from %q to %q", t.TagStatus, newStatus)
	}
	return nil
}

// Key returns the ledger key for this tag.
func (t *Tag) Key() string {
	return "TAG_" + t.TagSerialNumber
}

// TouchUpdatedAt sets UpdatedAt to the current time.
func (t *Tag) TouchUpdatedAt() {
	t.UpdatedAt = time.Now().UTC().Format(time.RFC3339)
}
