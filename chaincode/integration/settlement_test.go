// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

//go:build integration

package integration

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestSettlementLifecycle tests the complete settlement workflow:
// draft -> submitted -> accepted -> paid
func TestSettlementLifecycle(t *testing.T) {
	settlementID := uniqueID("SETTLE")

	// Create settlement - Org1 owes Org2
	settlement := map[string]interface{}{
		"settlementID":    settlementID,
		"periodStart":     "2026-01-01",
		"periodEnd":       "2026-01-31",
		"payorAgencyID":   "Org1",
		"payeeAgencyID":   "Org2",
		"grossAmount":     15000.00,
		"totalFees":       150.00,
		"netAmount":       14850.00,
		"chargeCount":     3000,
		"correctionCount": 15,
		"status":          "draft",
	}
	settlementJSON, _ := json.Marshal(settlement)

	t.Run("Step1_CreateSettlement", func(t *testing.T) {
		_, err := org1Client.SubmitTransaction("CreateSettlement", string(settlementJSON))
		require.NoError(t, err, "Failed to create settlement")
	})

	t.Run("Step2_GetSettlement", func(t *testing.T) {
		result, err := org1Client.EvaluateTransaction("GetSettlement", settlementID, "Org1", "Org2")
		require.NoError(t, err, "Failed to get settlement")

		var retrieved map[string]interface{}
		err = json.Unmarshal(result, &retrieved)
		require.NoError(t, err)

		assert.Equal(t, settlementID, retrieved["settlementID"])
		assert.Equal(t, "draft", retrieved["status"])
		assert.Equal(t, float64(15000.00), retrieved["grossAmount"])
		assert.Equal(t, float64(14850.00), retrieved["netAmount"])
	})

	t.Run("Step3_DraftToSubmitted", func(t *testing.T) {
		// Payor (Org1) submits the settlement
		_, err := org1Client.SubmitTransaction("UpdateSettlementStatus", settlementID, "Org1", "Org2", "submitted")
		require.NoError(t, err, "Failed to update settlement to submitted")

		// Verify
		result, err := org1Client.EvaluateTransaction("GetSettlement", settlementID, "Org1", "Org2")
		require.NoError(t, err)

		var retrieved map[string]interface{}
		json.Unmarshal(result, &retrieved)
		assert.Equal(t, "submitted", retrieved["status"])
	})

	t.Run("Step4_SubmittedToAccepted", func(t *testing.T) {
		// Payee (Org2) accepts the settlement
		_, err := org2Client.SubmitTransaction("UpdateSettlementStatus", settlementID, "Org1", "Org2", "accepted")
		require.NoError(t, err, "Failed to update settlement to accepted")

		// Verify
		result, err := org2Client.EvaluateTransaction("GetSettlement", settlementID, "Org1", "Org2")
		require.NoError(t, err)

		var retrieved map[string]interface{}
		json.Unmarshal(result, &retrieved)
		assert.Equal(t, "accepted", retrieved["status"])
	})

	t.Run("Step5_AcceptedToPaid", func(t *testing.T) {
		// Payor (Org1) marks as paid after transferring funds
		_, err := org1Client.SubmitTransaction("UpdateSettlementStatus", settlementID, "Org1", "Org2", "paid")
		require.NoError(t, err, "Failed to update settlement to paid")

		// Verify
		result, err := org1Client.EvaluateTransaction("GetSettlement", settlementID, "Org1", "Org2")
		require.NoError(t, err)

		var retrieved map[string]interface{}
		json.Unmarshal(result, &retrieved)
		assert.Equal(t, "paid", retrieved["status"])
	})
}

// TestSettlementDispute tests the dispute workflow.
func TestSettlementDispute(t *testing.T) {
	settlementID := uniqueID("SETTLE-DISP")

	// Create and submit settlement
	settlement := map[string]interface{}{
		"settlementID":    settlementID,
		"periodStart":     "2026-02-01",
		"periodEnd":       "2026-02-28",
		"payorAgencyID":   "Org3",
		"payeeAgencyID":   "Org4",
		"grossAmount":     20000.00,
		"totalFees":       200.00,
		"netAmount":       19800.00,
		"chargeCount":     4000,
		"correctionCount": 20,
		"status":          "draft",
	}
	settlementJSON, _ := json.Marshal(settlement)

	// Create settlement
	_, err := org3Client.SubmitTransaction("CreateSettlement", string(settlementJSON))
	require.NoError(t, err)

	// Submit settlement
	_, err = org3Client.SubmitTransaction("UpdateSettlementStatus", settlementID, "Org3", "Org4", "submitted")
	require.NoError(t, err)

	t.Run("PayeeCanDispute", func(t *testing.T) {
		// Payee (Org4) disputes the settlement
		_, err := org4Client.SubmitTransaction("UpdateSettlementStatus", settlementID, "Org3", "Org4", "disputed")
		require.NoError(t, err, "Failed to dispute settlement")

		// Verify
		result, err := org4Client.EvaluateTransaction("GetSettlement", settlementID, "Org3", "Org4")
		require.NoError(t, err)

		var retrieved map[string]interface{}
		json.Unmarshal(result, &retrieved)
		assert.Equal(t, "disputed", retrieved["status"])
	})
}

// TestSettlementValidation tests that invalid settlements are rejected.
func TestSettlementValidation(t *testing.T) {
	t.Run("RejectsDuplicateSettlement", func(t *testing.T) {
		settlementID := uniqueID("SETTLE-DUP")
		settlement := map[string]interface{}{
			"settlementID":    settlementID,
			"periodStart":     "2026-03-01",
			"periodEnd":       "2026-03-31",
			"payorAgencyID":   "Org1",
			"payeeAgencyID":   "Org2",
			"grossAmount":     5000.00,
			"totalFees":       50.00,
			"netAmount":       4950.00,
			"chargeCount":     1000,
			"correctionCount": 5,
			"status":          "draft",
		}
		settlementJSON, _ := json.Marshal(settlement)

		// First creation should succeed
		_, err := org1Client.SubmitTransaction("CreateSettlement", string(settlementJSON))
		require.NoError(t, err)

		// Second creation should fail
		_, err = org1Client.SubmitTransaction("CreateSettlement", string(settlementJSON))
		require.Error(t, err, "Should reject duplicate settlement")
		assert.Contains(t, err.Error(), "already exists")
	})

	t.Run("RejectsInvalidStatusTransition", func(t *testing.T) {
		settlementID := uniqueID("SETTLE-INV")
		settlement := map[string]interface{}{
			"settlementID":    settlementID,
			"periodStart":     "2026-04-01",
			"periodEnd":       "2026-04-30",
			"payorAgencyID":   "Org1",
			"payeeAgencyID":   "Org2",
			"grossAmount":     3000.00,
			"totalFees":       30.00,
			"netAmount":       2970.00,
			"chargeCount":     600,
			"correctionCount": 3,
			"status":          "draft",
		}
		settlementJSON, _ := json.Marshal(settlement)

		_, err := org1Client.SubmitTransaction("CreateSettlement", string(settlementJSON))
		require.NoError(t, err)

		// Try to go from draft directly to paid (invalid - must go through submitted and accepted)
		_, err = org1Client.SubmitTransaction("UpdateSettlementStatus", settlementID, "Org1", "Org2", "paid")
		require.Error(t, err, "Should reject invalid status transition")
		assert.Contains(t, err.Error(), "cannot transition")
	})

	t.Run("RejectsPeriodEndBeforeStart", func(t *testing.T) {
		settlement := map[string]interface{}{
			"settlementID":    uniqueID("SETTLE-DATE"),
			"periodStart":     "2026-05-31", // End is before start
			"periodEnd":       "2026-05-01",
			"payorAgencyID":   "Org1",
			"payeeAgencyID":   "Org2",
			"grossAmount":     1000.00,
			"totalFees":       10.00,
			"netAmount":       990.00,
			"chargeCount":     200,
			"correctionCount": 1,
			"status":          "draft",
		}
		settlementJSON, _ := json.Marshal(settlement)

		_, err := org1Client.SubmitTransaction("CreateSettlement", string(settlementJSON))
		require.Error(t, err, "Should reject settlement with period end before start")
		assert.Contains(t, err.Error(), "periodEnd must be after periodStart")
	})
}

// TestGetSettlementsByAgencyPair tests the query functionality.
func TestGetSettlementsByAgencyPair(t *testing.T) {
	// Create multiple settlements between Org1 and Org2
	for i := 0; i < 3; i++ {
		settlement := map[string]interface{}{
			"settlementID":    uniqueID("SETTLE-PAIR"),
			"periodStart":     "2026-06-01",
			"periodEnd":       "2026-06-30",
			"payorAgencyID":   "Org1",
			"payeeAgencyID":   "Org2",
			"grossAmount":     float64((i + 1) * 1000),
			"totalFees":       float64((i + 1) * 10),
			"netAmount":       float64((i+1)*1000 - (i+1)*10),
			"chargeCount":     (i + 1) * 100,
			"correctionCount": i,
			"status":          "draft",
		}
		settlementJSON, _ := json.Marshal(settlement)
		_, err := org1Client.SubmitTransaction("CreateSettlement", string(settlementJSON))
		require.NoError(t, err)
	}

	t.Run("ReturnsSettlementsForAgencyPair", func(t *testing.T) {
		result, err := org1Client.EvaluateTransaction("GetSettlementsByAgencyPair", "Org1", "Org2")
		require.NoError(t, err)

		var settlements []map[string]interface{}
		err = json.Unmarshal(result, &settlements)
		require.NoError(t, err)

		// Should have at least the 3 settlements we created
		assert.GreaterOrEqual(t, len(settlements), 3, "Expected at least 3 settlements")

		// Verify all are for the correct agency pair
		for _, s := range settlements {
			payor := s["payorAgencyID"].(string)
			payee := s["payeeAgencyID"].(string)
			validPair := (payor == "Org1" && payee == "Org2") || (payor == "Org2" && payee == "Org1")
			assert.True(t, validPair)
		}
	})
}
