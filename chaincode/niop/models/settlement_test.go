// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func validSettlement() Settlement {
	return Settlement{
		SettlementID:    "SETTLE-TEST-001",
		PeriodStart:     "2026-01-01",
		PeriodEnd:       "2026-01-31",
		PayorAgencyID:   "ORG1",
		PayeeAgencyID:   "ORG2",
		GrossAmount:     15000.00,
		TotalFees:       150.00,
		NetAmount:       14850.00,
		ChargeCount:     3000,
		CorrectionCount: 15,
		Status:          "draft",
	}
}

func TestSettlement_Validate(t *testing.T) {
	t.Run("valid settlement passes validation", func(t *testing.T) {
		s := validSettlement()
		assert.NoError(t, s.Validate())
	})

	t.Run("valid settlement with zero corrections", func(t *testing.T) {
		s := validSettlement()
		s.CorrectionCount = 0
		assert.NoError(t, s.Validate())
	})

	t.Run("valid settlement same day period", func(t *testing.T) {
		s := validSettlement()
		s.PeriodStart = "2026-01-15"
		s.PeriodEnd = "2026-01-15"
		assert.NoError(t, s.Validate())
	})
}

func TestSettlement_Validate_RequiredFields(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Settlement)
		wantErr string
	}{
		{
			name:    "missing settlementID",
			modify:  func(s *Settlement) { s.SettlementID = "" },
			wantErr: "settlementID is required",
		},
		{
			name:    "missing periodStart",
			modify:  func(s *Settlement) { s.PeriodStart = "" },
			wantErr: "periodStart is required",
		},
		{
			name:    "missing periodEnd",
			modify:  func(s *Settlement) { s.PeriodEnd = "" },
			wantErr: "periodEnd is required",
		},
		{
			name:    "missing payorAgencyID",
			modify:  func(s *Settlement) { s.PayorAgencyID = "" },
			wantErr: "payorAgencyID is required",
		},
		{
			name:    "missing payeeAgencyID",
			modify:  func(s *Settlement) { s.PayeeAgencyID = "" },
			wantErr: "payeeAgencyID is required",
		},
		{
			name:    "missing status",
			modify:  func(s *Settlement) { s.Status = "" },
			wantErr: "status is required",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			s := validSettlement()
			tt.modify(&s)
			err := s.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestSettlement_Validate_InvalidEnums(t *testing.T) {
	s := validSettlement()
	s.Status = "closed"
	err := s.Validate()
	require.Error(t, err)
	assert.Contains(t, err.Error(), "invalid status")
}

func TestSettlement_Validate_SameAgency(t *testing.T) {
	s := validSettlement()
	s.PayorAgencyID = "ORG1"
	s.PayeeAgencyID = "ORG1"
	err := s.Validate()
	require.Error(t, err)
	assert.Contains(t, err.Error(), "must be different")
}

func TestSettlement_Validate_PeriodEndBeforeStart(t *testing.T) {
	s := validSettlement()
	s.PeriodStart = "2026-02-01"
	s.PeriodEnd = "2026-01-15"
	err := s.Validate()
	require.Error(t, err)
	assert.Contains(t, err.Error(), "periodEnd")
	assert.Contains(t, err.Error(), "must not be before")
}

func TestSettlement_Validate_NegativeValues(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Settlement)
		wantErr string
	}{
		{
			name:    "negative grossAmount",
			modify:  func(s *Settlement) { s.GrossAmount = -1.0 },
			wantErr: "grossAmount must be >= 0",
		},
		{
			name:    "negative totalFees",
			modify:  func(s *Settlement) { s.TotalFees = -1.0 },
			wantErr: "totalFees must be >= 0",
		},
		{
			name:    "negative netAmount",
			modify:  func(s *Settlement) { s.NetAmount = -1.0 },
			wantErr: "netAmount must be >= 0",
		},
		{
			name:    "negative chargeCount",
			modify:  func(s *Settlement) { s.ChargeCount = -1 },
			wantErr: "chargeCount must be >= 0",
		},
		{
			name:    "negative correctionCount",
			modify:  func(s *Settlement) { s.CorrectionCount = -1 },
			wantErr: "correctionCount must be >= 0",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			s := validSettlement()
			tt.modify(&s)
			err := s.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestSettlement_ValidateStatusTransition(t *testing.T) {
	tests := []struct {
		name      string
		from      string
		to        string
		wantErr   bool
		errSubstr string
	}{
		{"draft->submitted", "draft", "submitted", false, ""},
		{"submitted->accepted", "submitted", "accepted", false, ""},
		{"submitted->disputed", "submitted", "disputed", false, ""},
		{"accepted->paid", "accepted", "paid", false, ""},
		{"disputed->submitted", "disputed", "submitted", false, ""},
		{"disputed->accepted", "disputed", "accepted", false, ""},

		{"draft->accepted (invalid)", "draft", "accepted", true, "cannot transition"},
		{"draft->paid (invalid)", "draft", "paid", true, "cannot transition"},
		{"submitted->draft (invalid)", "submitted", "draft", true, "cannot transition"},
		{"accepted->draft (invalid)", "accepted", "draft", true, "cannot transition"},
		{"paid->any (terminal)", "paid", "draft", true, "no transitions allowed"},
		{"same status", "draft", "draft", true, "already in status"},
		{"invalid target", "draft", "void", true, "invalid target status"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			s := validSettlement()
			s.Status = tt.from
			err := s.ValidateStatusTransition(tt.to)
			if tt.wantErr {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tt.errSubstr)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestSettlement_Key(t *testing.T) {
	s := Settlement{SettlementID: "SETTLE-001"}
	assert.Equal(t, "SETTLEMENT_SETTLE-001", s.Key())
}

func TestSettlement_SetCreatedAt(t *testing.T) {
	s := validSettlement()
	assert.Empty(t, s.CreatedAt)
	assert.Empty(t, s.DocType)
	s.SetCreatedAt()
	assert.NotEmpty(t, s.CreatedAt)
	assert.Equal(t, "settlement", s.DocType)
}

func TestSettlement_CollectionName(t *testing.T) {
	t.Run("alphabetical order", func(t *testing.T) {
		s := Settlement{PayorAgencyID: "ORG1", PayeeAgencyID: "ORG2"}
		assert.Equal(t, "charges_ORG1_ORG2", s.CollectionName())
	})

	t.Run("reversed order same result", func(t *testing.T) {
		s := Settlement{PayorAgencyID: "ORG2", PayeeAgencyID: "ORG1"}
		assert.Equal(t, "charges_ORG1_ORG2", s.CollectionName())
	})
}

func TestSettlement_Validate_AllStatuses(t *testing.T) {
	for _, status := range ValidSettlementStatuses {
		t.Run(status, func(t *testing.T) {
			s := validSettlement()
			s.Status = status
			assert.NoError(t, s.Validate())
		})
	}
}

func TestSettlement_Validate_ZeroAmounts(t *testing.T) {
	s := validSettlement()
	s.GrossAmount = 0
	s.TotalFees = 0
	s.NetAmount = 0
	s.ChargeCount = 0
	s.CorrectionCount = 0
	assert.NoError(t, s.Validate())
}
