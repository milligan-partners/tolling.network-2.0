// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"testing"

	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func validCorrection() *models.Correction {
	return &models.Correction{
		CorrectionID:     "CORR-TEST-001",
		OriginalChargeID: "CHG-TEST-001",
		CorrectionSeqNo:  1,
		CorrectionReason: "C",
		FromAgencyID:     "BATA",
		ToAgencyID:       "TCA",
		RecordType:       "TB01A",
		Amount:           3.50,
	}
}

func TestCreateCorrection(t *testing.T) {
	contract := &CorrectionContract{}

	t.Run("creates valid correction", func(t *testing.T) {
		ctx := newMockContext()
		correction := validCorrection()
		correctionJSON, _ := json.Marshal(correction)

		err := contract.CreateCorrection(ctx, string(correctionJSON))
		require.NoError(t, err)

		// Key format: CORRECTION_{chargeID}_{seqNo}
		bytes, err := ctx.stub.GetPrivateData("charges_BATA_TCA", "CORRECTION_CHG-TEST-001_001")
		require.NoError(t, err)
		require.NotNil(t, bytes)

		var stored models.Correction
		err = json.Unmarshal(bytes, &stored)
		require.NoError(t, err)
		assert.Equal(t, "CORR-TEST-001", stored.CorrectionID)
		assert.Equal(t, 1, stored.CorrectionSeqNo)
		assert.NotEmpty(t, stored.CreatedAt)
	})

	t.Run("rejects duplicate correction", func(t *testing.T) {
		ctx := newMockContext()
		correction := validCorrection()
		correctionJSON, _ := json.Marshal(correction)

		err := contract.CreateCorrection(ctx, string(correctionJSON))
		require.NoError(t, err)

		err = contract.CreateCorrection(ctx, string(correctionJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "already exists")
	})

	t.Run("rejects invalid correction reason", func(t *testing.T) {
		ctx := newMockContext()
		correction := validCorrection()
		correction.CorrectionReason = "X" // invalid
		correctionJSON, _ := json.Marshal(correction)

		err := contract.CreateCorrection(ctx, string(correctionJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid correctionReason")
	})

	t.Run("rejects invalid record type", func(t *testing.T) {
		ctx := newMockContext()
		correction := validCorrection()
		correction.RecordType = "TB01" // missing A suffix
		correctionJSON, _ := json.Marshal(correction)

		err := contract.CreateCorrection(ctx, string(correctionJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid correction recordType")
	})

	t.Run("rejects sequence number out of range", func(t *testing.T) {
		ctx := newMockContext()
		correction := validCorrection()
		correction.CorrectionSeqNo = 1000 // max is 999
		correctionJSON, _ := json.Marshal(correction)

		err := contract.CreateCorrection(ctx, string(correctionJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "correctionSeqNo must be between")
	})
}

func TestGetCorrection(t *testing.T) {
	contract := &CorrectionContract{}

	t.Run("retrieves existing correction", func(t *testing.T) {
		ctx := newMockContext()
		correction := validCorrection()
		correctionJSON, _ := json.Marshal(correction)
		_ = contract.CreateCorrection(ctx, string(correctionJSON))

		result, err := contract.GetCorrection(ctx, "CHG-TEST-001", 1, "BATA", "TCA")
		require.NoError(t, err)
		require.NotNil(t, result)
		assert.Equal(t, "CORR-TEST-001", result.CorrectionID)
	})

	t.Run("returns error for nonexistent correction", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetCorrection(ctx, "CHG-NONEXISTENT", 1, "BATA", "TCA")
		require.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "not found")
	})
}

func TestGetCorrectionsForCharge(t *testing.T) {
	contract := &CorrectionContract{}

	t.Run("returns empty list when no corrections", func(t *testing.T) {
		ctx := newEnhancedMockContext()

		result, err := contract.GetCorrectionsForCharge(ctx, "CHG-TEST-001", "BATA", "TCA")
		require.NoError(t, err)
		assert.Empty(t, result)
	})

	t.Run("returns corrections for charge", func(t *testing.T) {
		ctx := newEnhancedMockContext()

		// Create multiple corrections for same charge
		corr1 := validCorrection()
		corr1JSON, _ := json.Marshal(corr1)
		_ = contract.CreateCorrection(ctx, string(corr1JSON))

		corr2 := validCorrection()
		corr2.CorrectionID = "CORR-TEST-002"
		corr2.CorrectionSeqNo = 2
		corr2JSON, _ := json.Marshal(corr2)
		_ = contract.CreateCorrection(ctx, string(corr2JSON))

		result, err := contract.GetCorrectionsForCharge(ctx, "CHG-TEST-001", "BATA", "TCA")
		require.NoError(t, err)
		assert.Len(t, result, 2)
	})

	t.Run("only returns corrections for specified charge", func(t *testing.T) {
		ctx := newEnhancedMockContext()

		// Create correction for CHG-TEST-001
		corr1 := validCorrection()
		corr1JSON, _ := json.Marshal(corr1)
		_ = contract.CreateCorrection(ctx, string(corr1JSON))

		// Create correction for different charge
		corr2 := validCorrection()
		corr2.CorrectionID = "CORR-TEST-002"
		corr2.OriginalChargeID = "CHG-TEST-999"
		corr2JSON, _ := json.Marshal(corr2)
		_ = contract.CreateCorrection(ctx, string(corr2JSON))

		result, err := contract.GetCorrectionsForCharge(ctx, "CHG-TEST-001", "BATA", "TCA")
		require.NoError(t, err)
		assert.Len(t, result, 1)
		assert.Equal(t, "CHG-TEST-001", result[0].OriginalChargeID)
	})
}
