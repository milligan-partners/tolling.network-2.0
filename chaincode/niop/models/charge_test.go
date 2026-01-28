// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func validCharge() Charge {
	return Charge{
		ChargeID:        "CHG-TEST-001",
		ChargeType:      "toll_tag",
		RecordType:      "TB01",
		Protocol:        "niop",
		AwayAgencyID:    "ORG2",
		HomeAgencyID:    "ORG1",
		TagSerialNumber: "TEST.000000001",
		FacilityID:      "SR73",
		Plaza:           "CATALINA",
		ExitDateTime:    "2026-01-15T08:30:00Z",
		VehicleClass:    2,
		Amount:          4.75,
		Fee:             0.05,
		NetAmount:       4.70,
		Status:          "pending",
	}
}

func validVideoCharge() Charge {
	return Charge{
		ChargeID:     "CHG-TEST-002",
		ChargeType:   "toll_video",
		RecordType:   "VB01",
		Protocol:     "niop",
		AwayAgencyID: "ORG2",
		HomeAgencyID: "ORG1",
		PlateCountry: "US",
		PlateState:   "CA",
		PlateNumber:  "7ABC123",
		FacilityID:   "SR73",
		Plaza:        "CATALINA",
		ExitDateTime: "2026-01-15T08:30:00Z",
		VehicleClass: 2,
		Amount:       6.50,
		Fee:          0.10,
		NetAmount:    6.40,
		Status:       "pending",
	}
}

func TestCharge_Validate(t *testing.T) {
	t.Run("valid tag-based charge", func(t *testing.T) {
		c := validCharge()
		assert.NoError(t, c.Validate())
	})

	t.Run("valid video-based charge", func(t *testing.T) {
		c := validVideoCharge()
		assert.NoError(t, c.Validate())
	})
}

func TestCharge_Validate_RequiredFields(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Charge)
		wantErr string
	}{
		{
			name:    "missing chargeID",
			modify:  func(c *Charge) { c.ChargeID = "" },
			wantErr: "chargeID is required",
		},
		{
			name:    "missing chargeType",
			modify:  func(c *Charge) { c.ChargeType = "" },
			wantErr: "chargeType is required",
		},
		{
			name:    "missing recordType",
			modify:  func(c *Charge) { c.RecordType = "" },
			wantErr: "recordType is required",
		},
		{
			name:    "missing protocol",
			modify:  func(c *Charge) { c.Protocol = "" },
			wantErr: "protocol is required",
		},
		{
			name:    "missing awayAgencyID",
			modify:  func(c *Charge) { c.AwayAgencyID = "" },
			wantErr: "awayAgencyID is required",
		},
		{
			name:    "missing homeAgencyID",
			modify:  func(c *Charge) { c.HomeAgencyID = "" },
			wantErr: "homeAgencyID is required",
		},
		{
			name:    "missing facilityID",
			modify:  func(c *Charge) { c.FacilityID = "" },
			wantErr: "facilityID is required",
		},
		{
			name:    "missing exitDateTime",
			modify:  func(c *Charge) { c.ExitDateTime = "" },
			wantErr: "exitDateTime is required",
		},
		{
			name:    "missing status",
			modify:  func(c *Charge) { c.Status = "" },
			wantErr: "status is required",
		},
		{
			name:    "vehicleClass zero",
			modify:  func(c *Charge) { c.VehicleClass = 0 },
			wantErr: "vehicleClass must be >= 1",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := validCharge()
			tt.modify(&c)
			err := c.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestCharge_Validate_InvalidEnums(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Charge)
		wantErr string
	}{
		{
			name:    "invalid chargeType",
			modify:  func(c *Charge) { c.ChargeType = "ferry" },
			wantErr: "invalid chargeType",
		},
		{
			name:    "invalid recordType",
			modify:  func(c *Charge) { c.RecordType = "XX99" },
			wantErr: "invalid recordType",
		},
		{
			name:    "invalid protocol",
			modify:  func(c *Charge) { c.Protocol = "soap" },
			wantErr: "invalid protocol",
		},
		{
			name:    "invalid status",
			modify:  func(c *Charge) { c.Status = "cancelled" },
			wantErr: "invalid status",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := validCharge()
			tt.modify(&c)
			err := c.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestCharge_Validate_SameAgency(t *testing.T) {
	c := validCharge()
	c.HomeAgencyID = "ORG2"
	c.AwayAgencyID = "ORG2"
	err := c.Validate()
	require.Error(t, err)
	assert.Contains(t, err.Error(), "must be different")
}

func TestCharge_Validate_NegativeAmounts(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Charge)
		wantErr string
	}{
		{
			name:    "negative amount",
			modify:  func(c *Charge) { c.Amount = -1.00 },
			wantErr: "amount must be >= 0",
		},
		{
			name:    "negative fee",
			modify:  func(c *Charge) { c.Fee = -0.05 },
			wantErr: "fee must be >= 0",
		},
		{
			name:    "negative netAmount",
			modify:  func(c *Charge) { c.NetAmount = -1.00 },
			wantErr: "netAmount must be >= 0",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := validCharge()
			tt.modify(&c)
			err := c.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestCharge_Validate_TagBased_RequiresTagSerial(t *testing.T) {
	for _, rt := range []string{"TB01", "TC01", "TC02"} {
		t.Run(rt+"_missing_tag", func(t *testing.T) {
			c := validCharge()
			c.RecordType = rt
			c.TagSerialNumber = ""
			err := c.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), "tagSerialNumber is required")
		})
	}
}

func TestCharge_Validate_VideoBased_RequiresPlate(t *testing.T) {
	for _, rt := range []string{"VB01", "VC01", "VC02"} {
		t.Run(rt+"_missing_plateNumber", func(t *testing.T) {
			c := validVideoCharge()
			c.RecordType = rt
			c.PlateNumber = ""
			err := c.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), "plateNumber is required")
		})

		t.Run(rt+"_missing_plateState", func(t *testing.T) {
			c := validVideoCharge()
			c.RecordType = rt
			c.PlateState = ""
			err := c.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), "plateState is required")
		})
	}
}

func TestCharge_ValidateStatusTransition(t *testing.T) {
	tests := []struct {
		name      string
		from      string
		to        string
		wantErr   bool
		errSubstr string
	}{
		{"pending->posted", "pending", "posted", false, ""},
		{"pending->rejected", "pending", "rejected", false, ""},
		{"posted->disputed", "posted", "disputed", false, ""},
		{"posted->settled", "posted", "settled", false, ""},
		{"disputed->posted", "disputed", "posted", false, ""},
		{"disputed->settled", "disputed", "settled", false, ""},
		{"rejected->pending", "rejected", "pending", false, ""},

		{"pending->settled (invalid)", "pending", "settled", true, "cannot transition"},
		{"pending->disputed (invalid)", "pending", "disputed", true, "cannot transition"},
		{"posted->pending (invalid)", "posted", "pending", true, "cannot transition"},
		{"settled->any (terminal)", "settled", "pending", true, "no transitions allowed"},
		{"same status", "pending", "pending", true, "already in status"},
		{"invalid target", "pending", "void", true, "invalid target status"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := validCharge()
			c.Status = tt.from
			err := c.ValidateStatusTransition(tt.to)
			if tt.wantErr {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tt.errSubstr)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestCharge_Key(t *testing.T) {
	c := Charge{ChargeID: "CHG-001"}
	assert.Equal(t, "CHARGE_CHG-001", c.Key())
}

func TestCharge_SetCreatedAt(t *testing.T) {
	c := validCharge()
	assert.Empty(t, c.CreatedAt)
	c.SetCreatedAt()
	assert.NotEmpty(t, c.CreatedAt)
}

func TestCharge_CollectionName(t *testing.T) {
	t.Run("alphabetical order A-B", func(t *testing.T) {
		c := Charge{AwayAgencyID: "ORG2", HomeAgencyID: "ORG1"}
		assert.Equal(t, "charges_ORG2_ORG1", c.CollectionName())
	})

	t.Run("alphabetical order reversed", func(t *testing.T) {
		c := Charge{AwayAgencyID: "ORG1", HomeAgencyID: "ORG2"}
		assert.Equal(t, "charges_ORG2_ORG1", c.CollectionName())
	})

	t.Run("same collection regardless of direction", func(t *testing.T) {
		c1 := Charge{AwayAgencyID: "ORG4", HomeAgencyID: "ORG5"}
		c2 := Charge{AwayAgencyID: "ORG5", HomeAgencyID: "ORG4"}
		assert.Equal(t, c1.CollectionName(), c2.CollectionName())
	})
}

func TestCharge_Validate_AllChargeTypes(t *testing.T) {
	for _, ct := range ValidChargeTypes {
		t.Run(ct, func(t *testing.T) {
			c := validCharge()
			c.ChargeType = ct
			assert.NoError(t, c.Validate())
		})
	}
}

func TestCharge_Validate_AllRecordTypes(t *testing.T) {
	for _, rt := range ValidRecordTypes {
		t.Run(rt, func(t *testing.T) {
			c := validCharge()
			c.RecordType = rt
			// Video-based record types need plate info instead of tag
			if contains(videoBasedRecordTypes, rt) {
				c.TagSerialNumber = ""
				c.PlateNumber = "7ABC123"
				c.PlateState = "CA"
				c.PlateCountry = "US"
			}
			assert.NoError(t, c.Validate())
		})
	}
}

func TestCharge_Validate_AllProtocols(t *testing.T) {
	for _, p := range ValidChargeProtocols {
		t.Run(p, func(t *testing.T) {
			c := validCharge()
			c.Protocol = p
			assert.NoError(t, c.Validate())
		})
	}
}

func TestCharge_Validate_ZeroAmount(t *testing.T) {
	c := validCharge()
	c.Amount = 0
	c.Fee = 0
	c.NetAmount = 0
	assert.NoError(t, c.Validate())
}
