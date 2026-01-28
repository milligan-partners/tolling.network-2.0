// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func validReconciliation() Reconciliation {
	return Reconciliation{
		ReconciliationID:   "RECON-TEST-001",
		ChargeID:           "CHG-TEST-001",
		HomeAgencyID:       "ORG1",
		PostingDisposition: "P",
		PostedAmount:       4.75,
		PostedDateTime:     "2026-01-15T10:00:00Z",
		AdjustmentCount:    0,
		FlatFee:            0.05,
		PercentFee:         0.0,
	}
}

func TestReconciliation_Validate(t *testing.T) {
	t.Run("valid posted reconciliation", func(t *testing.T) {
		r := validReconciliation()
		assert.NoError(t, r.Validate())
	})

	t.Run("valid rejected reconciliation", func(t *testing.T) {
		r := validReconciliation()
		r.PostingDisposition = "D"
		r.PostedDateTime = ""
		r.PostedAmount = 0
		assert.NoError(t, r.Validate())
	})

	t.Run("valid reconciliation with discount plan", func(t *testing.T) {
		r := validReconciliation()
		r.DiscountPlanType = "commuter"
		assert.NoError(t, r.Validate())
	})
}

func TestReconciliation_Validate_RequiredFields(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Reconciliation)
		wantErr string
	}{
		{
			name:    "missing reconciliationID",
			modify:  func(r *Reconciliation) { r.ReconciliationID = "" },
			wantErr: "reconciliationID is required",
		},
		{
			name:    "missing chargeID",
			modify:  func(r *Reconciliation) { r.ChargeID = "" },
			wantErr: "chargeID is required",
		},
		{
			name:    "missing homeAgencyID",
			modify:  func(r *Reconciliation) { r.HomeAgencyID = "" },
			wantErr: "homeAgencyID is required",
		},
		{
			name:    "missing postingDisposition",
			modify:  func(r *Reconciliation) { r.PostingDisposition = "" },
			wantErr: "postingDisposition is required",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r := validReconciliation()
			tt.modify(&r)
			err := r.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestReconciliation_Validate_InvalidDisposition(t *testing.T) {
	r := validReconciliation()
	r.PostingDisposition = "X"
	err := r.Validate()
	require.Error(t, err)
	assert.Contains(t, err.Error(), "invalid postingDisposition")
}

func TestReconciliation_Validate_PostedRequiresDateTime(t *testing.T) {
	r := validReconciliation()
	r.PostingDisposition = "P"
	r.PostedDateTime = ""
	err := r.Validate()
	require.Error(t, err)
	assert.Contains(t, err.Error(), "postedDateTime is required")
}

func TestReconciliation_Validate_NonPostedDoesNotRequireDateTime(t *testing.T) {
	for _, disp := range []string{"D", "I", "N", "S", "T", "C", "O"} {
		t.Run(disp, func(t *testing.T) {
			r := validReconciliation()
			r.PostingDisposition = disp
			r.PostedDateTime = ""
			assert.NoError(t, r.Validate())
		})
	}
}

func TestReconciliation_Validate_NegativeValues(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Reconciliation)
		wantErr string
	}{
		{
			name:    "negative postedAmount",
			modify:  func(r *Reconciliation) { r.PostedAmount = -1.0 },
			wantErr: "postedAmount must be >= 0",
		},
		{
			name:    "negative adjustmentCount",
			modify:  func(r *Reconciliation) { r.AdjustmentCount = -1 },
			wantErr: "adjustmentCount must be >= 0",
		},
		{
			name:    "negative flatFee",
			modify:  func(r *Reconciliation) { r.FlatFee = -0.01 },
			wantErr: "flatFee must be >= 0",
		},
		{
			name:    "negative percentFee",
			modify:  func(r *Reconciliation) { r.PercentFee = -1.0 },
			wantErr: "percentFee must be >= 0",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r := validReconciliation()
			tt.modify(&r)
			err := r.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestReconciliation_Validate_PostedAmountCanDiffer(t *testing.T) {
	r := validReconciliation()
	r.PostedAmount = 3.50 // Different from original charge amount
	r.AdjustmentCount = 1
	assert.NoError(t, r.Validate())
}

func TestReconciliation_Key(t *testing.T) {
	r := Reconciliation{ChargeID: "CHG-001"}
	assert.Equal(t, "RECON_CHG-001", r.Key())
}

func TestReconciliation_SetCreatedAt(t *testing.T) {
	r := validReconciliation()
	assert.Empty(t, r.CreatedAt)
	assert.Empty(t, r.DocType)
	r.SetCreatedAt()
	assert.NotEmpty(t, r.CreatedAt)
	assert.Equal(t, "reconciliation", r.DocType)
}

func TestReconciliation_IsPosted(t *testing.T) {
	t.Run("posted returns true", func(t *testing.T) {
		r := validReconciliation()
		r.PostingDisposition = "P"
		assert.True(t, r.IsPosted())
	})

	t.Run("non-posted returns false", func(t *testing.T) {
		for _, disp := range []string{"D", "I", "N", "S", "T", "C", "O"} {
			t.Run(disp, func(t *testing.T) {
				r := validReconciliation()
				r.PostingDisposition = disp
				assert.False(t, r.IsPosted())
			})
		}
	})
}

func TestReconciliation_Validate_AllDispositions(t *testing.T) {
	for _, disp := range ValidPostingDispositions {
		t.Run(disp, func(t *testing.T) {
			r := validReconciliation()
			r.PostingDisposition = disp
			if disp != "P" {
				r.PostedDateTime = ""
			}
			assert.NoError(t, r.Validate())
		})
	}
}
