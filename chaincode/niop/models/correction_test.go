// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func validCorrection() Correction {
	return Correction{
		CorrectionID:     "CORR-TEST-001",
		OriginalChargeID: "CHG-TEST-001",
		CorrectionSeqNo:  1,
		CorrectionReason: "C",
		FromAgencyID:     "ORG2",
		ToAgencyID:       "ORG1",
		RecordType:       "TB01A",
		Amount:           3.50,
	}
}

func TestCorrection_Validate(t *testing.T) {
	t.Run("valid correction passes validation", func(t *testing.T) {
		c := validCorrection()
		assert.NoError(t, c.Validate())
	})

	t.Run("valid correction with resubmit reason", func(t *testing.T) {
		c := validCorrection()
		c.ResubmitReason = "R"
		c.ResubmitCount = 1
		assert.NoError(t, c.Validate())
	})

	t.Run("valid correction with zero amount", func(t *testing.T) {
		c := validCorrection()
		c.Amount = 0
		assert.NoError(t, c.Validate())
	})

	t.Run("valid correction with seqNo 0", func(t *testing.T) {
		c := validCorrection()
		c.CorrectionSeqNo = 0
		assert.NoError(t, c.Validate())
	})

	t.Run("valid correction with seqNo 999", func(t *testing.T) {
		c := validCorrection()
		c.CorrectionSeqNo = 999
		assert.NoError(t, c.Validate())
	})
}

func TestCorrection_Validate_RequiredFields(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Correction)
		wantErr string
	}{
		{
			name:    "missing correctionID",
			modify:  func(c *Correction) { c.CorrectionID = "" },
			wantErr: "correctionID is required",
		},
		{
			name:    "missing originalChargeID",
			modify:  func(c *Correction) { c.OriginalChargeID = "" },
			wantErr: "originalChargeID is required",
		},
		{
			name:    "missing correctionReason",
			modify:  func(c *Correction) { c.CorrectionReason = "" },
			wantErr: "correctionReason is required",
		},
		{
			name:    "missing fromAgencyID",
			modify:  func(c *Correction) { c.FromAgencyID = "" },
			wantErr: "fromAgencyID is required",
		},
		{
			name:    "missing toAgencyID",
			modify:  func(c *Correction) { c.ToAgencyID = "" },
			wantErr: "toAgencyID is required",
		},
		{
			name:    "missing recordType",
			modify:  func(c *Correction) { c.RecordType = "" },
			wantErr: "recordType is required",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := validCorrection()
			tt.modify(&c)
			err := c.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestCorrection_Validate_InvalidEnums(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Correction)
		wantErr string
	}{
		{
			name:    "invalid correctionReason",
			modify:  func(c *Correction) { c.CorrectionReason = "X" },
			wantErr: "invalid correctionReason",
		},
		{
			name:    "invalid resubmitReason",
			modify:  func(c *Correction) { c.ResubmitReason = "Q" },
			wantErr: "invalid resubmitReason",
		},
		{
			name:    "invalid recordType (no A suffix)",
			modify:  func(c *Correction) { c.RecordType = "TB01" },
			wantErr: "invalid correction recordType",
		},
		{
			name:    "invalid recordType (unknown)",
			modify:  func(c *Correction) { c.RecordType = "XX99A" },
			wantErr: "invalid correction recordType",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := validCorrection()
			tt.modify(&c)
			err := c.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestCorrection_Validate_SeqNoRange(t *testing.T) {
	t.Run("seqNo below range", func(t *testing.T) {
		c := validCorrection()
		c.CorrectionSeqNo = -1
		err := c.Validate()
		require.Error(t, err)
		assert.Contains(t, err.Error(), "correctionSeqNo must be between 0 and 999")
	})

	t.Run("seqNo above range", func(t *testing.T) {
		c := validCorrection()
		c.CorrectionSeqNo = 1000
		err := c.Validate()
		require.Error(t, err)
		assert.Contains(t, err.Error(), "correctionSeqNo must be between 0 and 999")
	})
}

func TestCorrection_Validate_SameAgency(t *testing.T) {
	c := validCorrection()
	c.FromAgencyID = "ORG1"
	c.ToAgencyID = "ORG1"
	err := c.Validate()
	require.Error(t, err)
	assert.Contains(t, err.Error(), "must be different")
}

func TestCorrection_Validate_NegativeAmount(t *testing.T) {
	c := validCorrection()
	c.Amount = -1.00
	err := c.Validate()
	require.Error(t, err)
	assert.Contains(t, err.Error(), "amount must be >= 0")
}

func TestCorrection_Key(t *testing.T) {
	c := Correction{OriginalChargeID: "CHG-001", CorrectionSeqNo: 3}
	assert.Equal(t, "CORRECTION_CHG-001_003", c.Key())
}

func TestCorrection_Key_SeqNoPadding(t *testing.T) {
	tests := []struct {
		seqNo int
		want  string
	}{
		{0, "CORRECTION_CHG-001_000"},
		{1, "CORRECTION_CHG-001_001"},
		{42, "CORRECTION_CHG-001_042"},
		{999, "CORRECTION_CHG-001_999"},
	}

	for _, tt := range tests {
		c := Correction{OriginalChargeID: "CHG-001", CorrectionSeqNo: tt.seqNo}
		assert.Equal(t, tt.want, c.Key())
	}
}

func TestCorrection_SetCreatedAt(t *testing.T) {
	c := validCorrection()
	assert.Empty(t, c.CreatedAt)
	assert.Empty(t, c.DocType)
	c.SetCreatedAt()
	assert.NotEmpty(t, c.CreatedAt)
	assert.Equal(t, "correction", c.DocType)
}

func TestCorrection_CollectionName(t *testing.T) {
	t.Run("alphabetical order", func(t *testing.T) {
		c := Correction{FromAgencyID: "ORG1", ToAgencyID: "ORG2"}
		assert.Equal(t, "charges_ORG1_ORG2", c.CollectionName())
	})

	t.Run("reversed order same result", func(t *testing.T) {
		c := Correction{FromAgencyID: "ORG2", ToAgencyID: "ORG1"}
		assert.Equal(t, "charges_ORG1_ORG2", c.CollectionName())
	})
}

func TestCorrection_Validate_AllReasons(t *testing.T) {
	for _, reason := range ValidCorrectionReasons {
		t.Run(reason, func(t *testing.T) {
			c := validCorrection()
			c.CorrectionReason = reason
			assert.NoError(t, c.Validate())
		})
	}
}

func TestCorrection_Validate_AllRecordTypes(t *testing.T) {
	for _, rt := range ValidCorrectionRecordTypes {
		t.Run(rt, func(t *testing.T) {
			c := validCorrection()
			c.RecordType = rt
			assert.NoError(t, c.Validate())
		})
	}
}

func TestCorrection_Validate_AllResubmitReasons(t *testing.T) {
	for _, rr := range ValidResubmitReasons {
		t.Run(rr, func(t *testing.T) {
			c := validCorrection()
			c.ResubmitReason = rr
			assert.NoError(t, c.Validate())
		})
	}
}
