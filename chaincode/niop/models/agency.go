// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"fmt"
	"time"
)

// Agency represents a toll operator, hub, clearinghouse, or transit authority
// on the Tolling.Network. Every other entity is scoped by an agency.
type Agency struct {
	DocType          string   `json:"docType"`
	AgencyID         string   `json:"agencyID"`
	Name             string   `json:"name"`
	Consortium       []string `json:"consortium"`
	HubID            string   `json:"hubID,omitempty"`
	State            string   `json:"state"`
	Role             string   `json:"role"`
	ConnectivityMode string   `json:"connectivityMode"`
	Status           string   `json:"status"`
	Capabilities     []string `json:"capabilities"`
	ProtocolSupport  []string `json:"protocolSupport"`
	CreatedAt        string   `json:"createdAt"`
	UpdatedAt        string   `json:"updatedAt"`
}

// Valid roles for an agency.
var ValidRoles = []string{"toll_operator", "hub", "clearinghouse", "transit_authority"}

// Valid connectivity modes.
var ValidConnectivityModes = []string{"direct", "hub_routed", "both"}

// Valid agency statuses.
var ValidAgencyStatuses = []string{"active", "suspended", "onboarding"}

// Valid consortium identifiers.
var ValidConsortiums = []string{"EZIOP", "CUSIOP", "SEIOP", "WRTO"}

// Valid capability values.
var ValidCapabilities = []string{"toll", "congestion_pricing", "parking", "transit"}

// Valid protocol support values.
var ValidProtocols = []string{"niop_1.02", "niop_2.0", "iag_1.51n", "iag_1.60", "ctoc_rev_a"}

// Validate checks all fields of an Agency and returns an error describing the
// first validation failure, or nil if the agency is valid.
func (a *Agency) Validate() error {
	if a.AgencyID == "" {
		return fmt.Errorf("agencyID is required")
	}
	if a.Name == "" {
		return fmt.Errorf("name is required")
	}
	if a.State == "" {
		return fmt.Errorf("state is required")
	}
	if a.Role == "" {
		return fmt.Errorf("role is required")
	}
	if !contains(ValidRoles, a.Role) {
		return fmt.Errorf("invalid role %q: must be one of %v", a.Role, ValidRoles)
	}
	if a.ConnectivityMode == "" {
		return fmt.Errorf("connectivityMode is required")
	}
	if !contains(ValidConnectivityModes, a.ConnectivityMode) {
		return fmt.Errorf("invalid connectivityMode %q: must be one of %v", a.ConnectivityMode, ValidConnectivityModes)
	}
	if a.Status == "" {
		return fmt.Errorf("status is required")
	}
	if !contains(ValidAgencyStatuses, a.Status) {
		return fmt.Errorf("invalid status %q: must be one of %v", a.Status, ValidAgencyStatuses)
	}
	for _, c := range a.Consortium {
		if !contains(ValidConsortiums, c) {
			return fmt.Errorf("invalid consortium %q: must be one of %v", c, ValidConsortiums)
		}
	}
	for _, cap := range a.Capabilities {
		if !contains(ValidCapabilities, cap) {
			return fmt.Errorf("invalid capability %q: must be one of %v", cap, ValidCapabilities)
		}
	}
	for _, p := range a.ProtocolSupport {
		if !contains(ValidProtocols, p) {
			return fmt.Errorf("invalid protocol %q: must be one of %v", p, ValidProtocols)
		}
	}
	if a.ConnectivityMode == "hub_routed" && a.HubID == "" {
		return fmt.Errorf("hubID is required when connectivityMode is hub_routed")
	}
	return nil
}

// Key returns the ledger key for this agency.
func (a *Agency) Key() string {
	return "AGENCY_" + a.AgencyID
}

// SetTimestamps sets CreatedAt, UpdatedAt, and DocType.
// Use on creation. For updates, call TouchUpdatedAt instead.
func (a *Agency) SetTimestamps() {
	now := time.Now().UTC().Format(time.RFC3339)
	a.DocType = "agency"
	a.CreatedAt = now
	a.UpdatedAt = now
}

// TouchUpdatedAt sets UpdatedAt to the current time.
func (a *Agency) TouchUpdatedAt() {
	a.UpdatedAt = time.Now().UTC().Format(time.RFC3339)
}

// contains checks if a string is in a slice.
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
