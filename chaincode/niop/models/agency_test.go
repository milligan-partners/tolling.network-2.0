// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// validAgency returns a minimal valid Agency for testing.
// Tests modify specific fields to trigger validation failures.
func validAgency() Agency {
	return Agency{
		AgencyID:         "ORG1",
		Name:             "Transportation Corridor Agencies",
		Consortium:       []string{"WRTO"},
		State:            "CA",
		Role:             "toll_operator",
		ConnectivityMode: "direct",
		Status:           "active",
		Capabilities:     []string{"toll"},
		ProtocolSupport:  []string{"ctoc_rev_a"},
	}
}

func TestAgency_Validate(t *testing.T) {
	t.Run("valid agency passes validation", func(t *testing.T) {
		a := validAgency()
		err := a.Validate()
		assert.NoError(t, err)
	})

	t.Run("valid agency with multiple consortiums", func(t *testing.T) {
		a := validAgency()
		a.Consortium = []string{"EZIOP", "CUSIOP"}
		err := a.Validate()
		assert.NoError(t, err)
	})

	t.Run("valid hub-routed agency with hubID", func(t *testing.T) {
		a := validAgency()
		a.ConnectivityMode = "hub_routed"
		a.HubID = "EZIOP"
		err := a.Validate()
		assert.NoError(t, err)
	})

	t.Run("valid agency with empty consortium list", func(t *testing.T) {
		a := validAgency()
		a.Consortium = nil
		err := a.Validate()
		assert.NoError(t, err)
	})

	t.Run("valid agency with all capabilities", func(t *testing.T) {
		a := validAgency()
		a.Capabilities = []string{"toll", "congestion_pricing", "parking", "transit"}
		err := a.Validate()
		assert.NoError(t, err)
	})
}

func TestAgency_Validate_RequiredFields(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Agency)
		wantErr string
	}{
		{
			name:    "missing agencyID",
			modify:  func(a *Agency) { a.AgencyID = "" },
			wantErr: "agencyID is required",
		},
		{
			name:    "missing name",
			modify:  func(a *Agency) { a.Name = "" },
			wantErr: "name is required",
		},
		{
			name:    "missing state",
			modify:  func(a *Agency) { a.State = "" },
			wantErr: "state is required",
		},
		{
			name:    "missing role",
			modify:  func(a *Agency) { a.Role = "" },
			wantErr: "role is required",
		},
		{
			name:    "missing connectivityMode",
			modify:  func(a *Agency) { a.ConnectivityMode = "" },
			wantErr: "connectivityMode is required",
		},
		{
			name:    "missing status",
			modify:  func(a *Agency) { a.Status = "" },
			wantErr: "status is required",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			a := validAgency()
			tt.modify(&a)
			err := a.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestAgency_Validate_InvalidEnums(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Agency)
		wantErr string
	}{
		{
			name:    "invalid role",
			modify:  func(a *Agency) { a.Role = "admin" },
			wantErr: "invalid role",
		},
		{
			name:    "invalid connectivityMode",
			modify:  func(a *Agency) { a.ConnectivityMode = "wireless" },
			wantErr: "invalid connectivityMode",
		},
		{
			name:    "invalid status",
			modify:  func(a *Agency) { a.Status = "deleted" },
			wantErr: "invalid status",
		},
		{
			name:    "invalid consortium",
			modify:  func(a *Agency) { a.Consortium = []string{"INVALID_HUB"} },
			wantErr: "invalid consortium",
		},
		{
			name:    "invalid capability",
			modify:  func(a *Agency) { a.Capabilities = []string{"flying"} },
			wantErr: "invalid capability",
		},
		{
			name:    "invalid protocol",
			modify:  func(a *Agency) { a.ProtocolSupport = []string{"niop_99.0"} },
			wantErr: "invalid protocol",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			a := validAgency()
			tt.modify(&a)
			err := a.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestAgency_Validate_HubRouted_RequiresHubID(t *testing.T) {
	t.Run("hub_routed without hubID", func(t *testing.T) {
		a := validAgency()
		a.ConnectivityMode = "hub_routed"
		a.HubID = ""
		err := a.Validate()
		require.Error(t, err)
		assert.Contains(t, err.Error(), "hubID is required")
	})

	t.Run("direct mode does not require hubID", func(t *testing.T) {
		a := validAgency()
		a.ConnectivityMode = "direct"
		a.HubID = ""
		err := a.Validate()
		assert.NoError(t, err)
	})

	t.Run("both mode does not require hubID", func(t *testing.T) {
		a := validAgency()
		a.ConnectivityMode = "both"
		a.HubID = ""
		err := a.Validate()
		assert.NoError(t, err)
	})
}

func TestAgency_Key(t *testing.T) {
	a := Agency{AgencyID: "ORG4"}
	assert.Equal(t, "AGENCY_ORG4", a.Key())
}

func TestAgency_SetTimestamps(t *testing.T) {
	a := validAgency()
	assert.Empty(t, a.CreatedAt)
	assert.Empty(t, a.UpdatedAt)
	assert.Empty(t, a.DocType)

	a.SetTimestamps()

	assert.NotEmpty(t, a.CreatedAt)
	assert.NotEmpty(t, a.UpdatedAt)
	assert.Equal(t, a.CreatedAt, a.UpdatedAt)
	assert.Equal(t, "agency", a.DocType)
}

func TestAgency_TouchUpdatedAt(t *testing.T) {
	a := validAgency()
	a.SetTimestamps()
	original := a.UpdatedAt

	a.TouchUpdatedAt()

	assert.NotEmpty(t, a.UpdatedAt)
	// UpdatedAt should be >= original (may be equal if test runs fast)
	assert.GreaterOrEqual(t, a.UpdatedAt, original)
}

func TestAgency_Validate_AllRoles(t *testing.T) {
	for _, role := range ValidRoles {
		t.Run(role, func(t *testing.T) {
			a := validAgency()
			a.Role = role
			err := a.Validate()
			assert.NoError(t, err)
		})
	}
}

func TestAgency_Validate_AllConnectivityModes(t *testing.T) {
	for _, mode := range ValidConnectivityModes {
		t.Run(mode, func(t *testing.T) {
			a := validAgency()
			a.ConnectivityMode = mode
			if mode == "hub_routed" {
				a.HubID = "EZIOP"
			}
			err := a.Validate()
			assert.NoError(t, err)
		})
	}
}

func TestAgency_Validate_AllStatuses(t *testing.T) {
	for _, status := range ValidAgencyStatuses {
		t.Run(status, func(t *testing.T) {
			a := validAgency()
			a.Status = status
			err := a.Validate()
			assert.NoError(t, err)
		})
	}
}
