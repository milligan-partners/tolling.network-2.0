// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"testing"

	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func validSettlement() *models.Settlement {
	return &models.Settlement{
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

func TestCreateSettlement(t *testing.T) {
	contract := &SettlementContract{}

	t.Run("creates valid settlement", func(t *testing.T) {
		ctx := newMockContext()
		settlement := validSettlement()
		settlementJSON, _ := json.Marshal(settlement)

		err := contract.CreateSettlement(ctx, string(settlementJSON))
		require.NoError(t, err)

		bytes, err := ctx.stub.GetPrivateData("charges_ORG2_ORG1", "SETTLEMENT_SETTLE-TEST-001")
		require.NoError(t, err)
		require.NotNil(t, bytes)

		var stored models.Settlement
		err = json.Unmarshal(bytes, &stored)
		require.NoError(t, err)
		assert.Equal(t, "SETTLE-TEST-001", stored.SettlementID)
		assert.Equal(t, "draft", stored.Status)
		assert.NotEmpty(t, stored.CreatedAt)
	})

	t.Run("rejects duplicate settlement", func(t *testing.T) {
		ctx := newMockContext()
		settlement := validSettlement()
		settlementJSON, _ := json.Marshal(settlement)

		err := contract.CreateSettlement(ctx, string(settlementJSON))
		require.NoError(t, err)

		err = contract.CreateSettlement(ctx, string(settlementJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "already exists")
	})

	t.Run("rejects period end before start", func(t *testing.T) {
		ctx := newMockContext()
		settlement := validSettlement()
		settlement.PeriodEnd = "2025-12-31" // before start
		settlementJSON, _ := json.Marshal(settlement)

		err := contract.CreateSettlement(ctx, string(settlementJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "periodEnd")
	})

	t.Run("rejects same payor and payee", func(t *testing.T) {
		ctx := newMockContext()
		settlement := validSettlement()
		settlement.PayeeAgencyID = "ORG1" // same as payor
		settlementJSON, _ := json.Marshal(settlement)

		err := contract.CreateSettlement(ctx, string(settlementJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "must be different")
	})

	t.Run("rejects invalid status", func(t *testing.T) {
		ctx := newMockContext()
		settlement := validSettlement()
		settlement.Status = "invalid_status"
		settlementJSON, _ := json.Marshal(settlement)

		err := contract.CreateSettlement(ctx, string(settlementJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid status")
	})
}

func TestGetSettlement(t *testing.T) {
	contract := &SettlementContract{}

	t.Run("retrieves existing settlement", func(t *testing.T) {
		ctx := newMockContext()
		settlement := validSettlement()
		settlementJSON, _ := json.Marshal(settlement)
		_ = contract.CreateSettlement(ctx, string(settlementJSON))

		result, err := contract.GetSettlement(ctx, "SETTLE-TEST-001", "ORG1", "ORG2")
		require.NoError(t, err)
		require.NotNil(t, result)
		assert.Equal(t, "SETTLE-TEST-001", result.SettlementID)
	})

	t.Run("retrieves with reversed agency order", func(t *testing.T) {
		ctx := newMockContext()
		settlement := validSettlement()
		settlementJSON, _ := json.Marshal(settlement)
		_ = contract.CreateSettlement(ctx, string(settlementJSON))

		// Pass agencies in reverse order - should still work
		result, err := contract.GetSettlement(ctx, "SETTLE-TEST-001", "ORG2", "ORG1")
		require.NoError(t, err)
		require.NotNil(t, result)
		assert.Equal(t, "SETTLE-TEST-001", result.SettlementID)
	})

	t.Run("returns error for nonexistent settlement", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetSettlement(ctx, "SETTLE-NONEXISTENT", "ORG1", "ORG2")
		require.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "not found")
	})
}

func TestUpdateSettlementStatus(t *testing.T) {
	contract := &SettlementContract{}

	t.Run("updates status with valid transition", func(t *testing.T) {
		ctx := newMockContext()
		settlement := validSettlement()
		settlementJSON, _ := json.Marshal(settlement)
		_ = contract.CreateSettlement(ctx, string(settlementJSON))

		// draft -> submitted is allowed
		err := contract.UpdateSettlementStatus(ctx, "SETTLE-TEST-001", "ORG1", "ORG2", "submitted")
		require.NoError(t, err)

		result, err := contract.GetSettlement(ctx, "SETTLE-TEST-001", "ORG1", "ORG2")
		require.NoError(t, err)
		assert.Equal(t, "submitted", result.Status)
	})

	t.Run("rejects invalid status transition", func(t *testing.T) {
		ctx := newMockContext()
		settlement := validSettlement()
		settlementJSON, _ := json.Marshal(settlement)
		_ = contract.CreateSettlement(ctx, string(settlementJSON))

		// draft -> paid is NOT allowed (must go through submitted, accepted)
		err := contract.UpdateSettlementStatus(ctx, "SETTLE-TEST-001", "ORG1", "ORG2", "paid")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "cannot transition")
	})

	t.Run("full lifecycle: draft -> submitted -> accepted -> paid", func(t *testing.T) {
		ctx := newMockContext()
		settlement := validSettlement()
		settlementJSON, _ := json.Marshal(settlement)
		_ = contract.CreateSettlement(ctx, string(settlementJSON))

		err := contract.UpdateSettlementStatus(ctx, "SETTLE-TEST-001", "ORG1", "ORG2", "submitted")
		require.NoError(t, err)

		err = contract.UpdateSettlementStatus(ctx, "SETTLE-TEST-001", "ORG1", "ORG2", "accepted")
		require.NoError(t, err)

		err = contract.UpdateSettlementStatus(ctx, "SETTLE-TEST-001", "ORG1", "ORG2", "paid")
		require.NoError(t, err)

		result, err := contract.GetSettlement(ctx, "SETTLE-TEST-001", "ORG1", "ORG2")
		require.NoError(t, err)
		assert.Equal(t, "paid", result.Status)
	})
}

func TestGetSettlementsByAgencyPair(t *testing.T) {
	contract := &SettlementContract{}

	t.Run("returns empty list when no settlements", func(t *testing.T) {
		ctx := newEnhancedMockContext()

		result, err := contract.GetSettlementsByAgencyPair(ctx, "ORG1", "ORG2")
		require.NoError(t, err)
		assert.Empty(t, result)
	})

	t.Run("returns settlements for agency pair", func(t *testing.T) {
		ctx := newEnhancedMockContext()

		// Create multiple settlements
		settlement1 := validSettlement()
		settlement1JSON, _ := json.Marshal(settlement1)
		_ = contract.CreateSettlement(ctx, string(settlement1JSON))

		settlement2 := validSettlement()
		settlement2.SettlementID = "SETTLE-TEST-002"
		settlement2JSON, _ := json.Marshal(settlement2)
		_ = contract.CreateSettlement(ctx, string(settlement2JSON))

		result, err := contract.GetSettlementsByAgencyPair(ctx, "ORG1", "ORG2")
		require.NoError(t, err)
		assert.Len(t, result, 2)
	})

	t.Run("returns settlements regardless of agency order", func(t *testing.T) {
		ctx := newEnhancedMockContext()

		settlement := validSettlement()
		settlementJSON, _ := json.Marshal(settlement)
		_ = contract.CreateSettlement(ctx, string(settlementJSON))

		// Query with reversed agency order
		result, err := contract.GetSettlementsByAgencyPair(ctx, "ORG2", "ORG1")
		require.NoError(t, err)
		assert.Len(t, result, 1)
		assert.Equal(t, "SETTLE-TEST-001", result[0].SettlementID)
	})
}

func TestGetSettlementsByStatus(t *testing.T) {
	contract := &SettlementContract{}

	t.Run("returns empty list when no matching status", func(t *testing.T) {
		ctx := newEnhancedMockContext()

		// Create a draft settlement
		settlement := validSettlement()
		settlementJSON, _ := json.Marshal(settlement)
		_ = contract.CreateSettlement(ctx, string(settlementJSON))

		// Query for submitted status (none exist)
		result, err := contract.GetSettlementsByStatus(ctx, "ORG1", "ORG2", "submitted")
		require.NoError(t, err)
		assert.Empty(t, result)
	})

	t.Run("returns settlements matching status", func(t *testing.T) {
		ctx := newEnhancedMockContext()

		// Create draft settlement
		settlement1 := validSettlement()
		settlement1JSON, _ := json.Marshal(settlement1)
		_ = contract.CreateSettlement(ctx, string(settlement1JSON))

		// Create and submit another settlement
		settlement2 := validSettlement()
		settlement2.SettlementID = "SETTLE-TEST-002"
		settlement2JSON, _ := json.Marshal(settlement2)
		_ = contract.CreateSettlement(ctx, string(settlement2JSON))
		_ = contract.UpdateSettlementStatus(ctx, "SETTLE-TEST-002", "ORG1", "ORG2", "submitted")

		// Query for draft status
		draftResult, err := contract.GetSettlementsByStatus(ctx, "ORG1", "ORG2", "draft")
		require.NoError(t, err)
		assert.Len(t, draftResult, 1)
		assert.Equal(t, "SETTLE-TEST-001", draftResult[0].SettlementID)

		// Query for submitted status
		submittedResult, err := contract.GetSettlementsByStatus(ctx, "ORG1", "ORG2", "submitted")
		require.NoError(t, err)
		assert.Len(t, submittedResult, 1)
		assert.Equal(t, "SETTLE-TEST-002", submittedResult[0].SettlementID)
	})
}

func TestSettlementCollectionNameSymmetry(t *testing.T) {
	// Settlement collection names must be symmetric like charges
	s1 := &models.Settlement{
		PayorAgencyID: "ORG1",
		PayeeAgencyID: "ORG2",
	}

	s2 := &models.Settlement{
		PayorAgencyID: "ORG2",
		PayeeAgencyID: "ORG1",
	}

	assert.Equal(t, s1.CollectionName(), s2.CollectionName())
	assert.Equal(t, "charges_ORG2_ORG1", s1.CollectionName())
}
