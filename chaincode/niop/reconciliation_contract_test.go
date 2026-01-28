// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"testing"

	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func validReconciliation() *models.Reconciliation {
	return &models.Reconciliation{
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

func TestCreateReconciliation(t *testing.T) {
	contract := &ReconciliationContract{}

	t.Run("creates valid reconciliation", func(t *testing.T) {
		ctx := newMockContext()
		recon := validReconciliation()
		reconJSON, _ := json.Marshal(recon)

		err := contract.CreateReconciliation(ctx, string(reconJSON))
		require.NoError(t, err)

		// Key format: RECON_{chargeID}
		bytes, err := ctx.stub.GetState("RECON_CHG-TEST-001")
		require.NoError(t, err)
		require.NotNil(t, bytes)

		var stored models.Reconciliation
		err = json.Unmarshal(bytes, &stored)
		require.NoError(t, err)
		assert.Equal(t, "RECON-TEST-001", stored.ReconciliationID)
		assert.Equal(t, "P", stored.PostingDisposition)
		assert.NotEmpty(t, stored.CreatedAt)
	})

	t.Run("rejects duplicate reconciliation", func(t *testing.T) {
		ctx := newMockContext()
		recon := validReconciliation()
		reconJSON, _ := json.Marshal(recon)

		err := contract.CreateReconciliation(ctx, string(reconJSON))
		require.NoError(t, err)

		err = contract.CreateReconciliation(ctx, string(reconJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "already exists")
	})

	t.Run("rejects invalid posting disposition", func(t *testing.T) {
		ctx := newMockContext()
		recon := validReconciliation()
		recon.PostingDisposition = "X" // invalid
		reconJSON, _ := json.Marshal(recon)

		err := contract.CreateReconciliation(ctx, string(reconJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid postingDisposition")
	})

	t.Run("rejects posted disposition without datetime", func(t *testing.T) {
		ctx := newMockContext()
		recon := validReconciliation()
		recon.PostedDateTime = "" // missing when disposition is P
		reconJSON, _ := json.Marshal(recon)

		err := contract.CreateReconciliation(ctx, string(reconJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "postedDateTime is required")
	})

	t.Run("allows non-posted disposition without datetime", func(t *testing.T) {
		ctx := newMockContext()
		recon := validReconciliation()
		recon.PostingDisposition = "D" // duplicate - doesn't need datetime
		recon.PostedDateTime = ""
		reconJSON, _ := json.Marshal(recon)

		err := contract.CreateReconciliation(ctx, string(reconJSON))
		require.NoError(t, err)
	})
}

func TestGetReconciliation(t *testing.T) {
	contract := &ReconciliationContract{}

	t.Run("retrieves existing reconciliation", func(t *testing.T) {
		ctx := newMockContext()
		recon := validReconciliation()
		reconJSON, _ := json.Marshal(recon)
		_ = contract.CreateReconciliation(ctx, string(reconJSON))

		result, err := contract.GetReconciliation(ctx, "CHG-TEST-001")
		require.NoError(t, err)
		require.NotNil(t, result)
		assert.Equal(t, "RECON-TEST-001", result.ReconciliationID)
		assert.Equal(t, "CHG-TEST-001", result.ChargeID)
	})

	t.Run("returns error for nonexistent reconciliation", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetReconciliation(ctx, "CHG-NONEXISTENT")
		require.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "not found")
	})
}

func TestGetReconciliationsByAgency(t *testing.T) {
	contract := &ReconciliationContract{}

	t.Run("returns empty list when no reconciliations", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetReconciliationsByAgency(ctx, "ORG1")
		require.NoError(t, err)
		assert.Empty(t, result)
	})

	t.Run("returns reconciliations for specific agency", func(t *testing.T) {
		ctx := newMockContext()

		recon1 := validReconciliation()
		recon1JSON, _ := json.Marshal(recon1)
		_ = contract.CreateReconciliation(ctx, string(recon1JSON))

		recon2 := validReconciliation()
		recon2.ReconciliationID = "RECON-TEST-002"
		recon2.ChargeID = "CHG-TEST-002"
		recon2JSON, _ := json.Marshal(recon2)
		_ = contract.CreateReconciliation(ctx, string(recon2JSON))

		recon3 := validReconciliation()
		recon3.ReconciliationID = "RECON-TEST-003"
		recon3.ChargeID = "CHG-TEST-003"
		recon3.HomeAgencyID = "ORG2" // different agency
		recon3JSON, _ := json.Marshal(recon3)
		_ = contract.CreateReconciliation(ctx, string(recon3JSON))

		result, err := contract.GetReconciliationsByAgency(ctx, "ORG1")
		require.NoError(t, err)
		assert.Len(t, result, 2)
	})
}

func TestGetReconciliationsByDisposition(t *testing.T) {
	contract := &ReconciliationContract{}

	t.Run("rejects invalid disposition", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetReconciliationsByDisposition(ctx, "X")
		require.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "invalid postingDisposition")
	})

	t.Run("returns reconciliations with specific disposition", func(t *testing.T) {
		ctx := newMockContext()

		recon1 := validReconciliation()
		recon1JSON, _ := json.Marshal(recon1)
		_ = contract.CreateReconciliation(ctx, string(recon1JSON))

		recon2 := validReconciliation()
		recon2.ReconciliationID = "RECON-TEST-002"
		recon2.ChargeID = "CHG-TEST-002"
		recon2.PostingDisposition = "D" // different disposition
		recon2.PostedDateTime = ""
		recon2JSON, _ := json.Marshal(recon2)
		_ = contract.CreateReconciliation(ctx, string(recon2JSON))

		result, err := contract.GetReconciliationsByDisposition(ctx, "P")
		require.NoError(t, err)
		assert.Len(t, result, 1)
		assert.Equal(t, "P", result[0].PostingDisposition)
	})
}
