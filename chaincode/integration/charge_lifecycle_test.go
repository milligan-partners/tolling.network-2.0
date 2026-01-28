// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

//go:build integration

package integration

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestChargeLifecycle tests the full charge lifecycle: create, get, update status.
func TestChargeLifecycle(t *testing.T) {
	chargeID := uniqueID("CHG")

	// Build charge JSON - Org2 (away) creates a charge for Org1 (home)
	charge := map[string]interface{}{
		"chargeID":        chargeID,
		"chargeType":      "toll_tag",
		"recordType":      "TB01",
		"protocol":        "niop",
		"awayAgencyID":    "Org2",
		"homeAgencyID":    "Org1",
		"tagSerialNumber": "TEST.000000001",
		"facilityID":      "SR73",
		"plaza":           "CATALINA",
		"exitDateTime":    "2026-01-15T08:30:00Z",
		"vehicleClass":    2,
		"amount":          4.75,
		"fee":             0.05,
		"netAmount":       4.70,
		"status":          "pending",
	}
	chargeJSON, err := json.Marshal(charge)
	require.NoError(t, err)

	t.Run("CreateCharge", func(t *testing.T) {
		// Org2 (away agency) submits the charge
		_, err := org2Client.SubmitTransaction("CreateCharge", string(chargeJSON))
		require.NoError(t, err, "Failed to create charge")
	})

	t.Run("GetCharge_ByAwayAgency", func(t *testing.T) {
		// Org2 retrieves its own charge
		result, err := org2Client.EvaluateTransaction("GetCharge", chargeID, "Org2", "Org1")
		require.NoError(t, err, "Failed to get charge as Org2")

		var retrieved map[string]interface{}
		err = json.Unmarshal(result, &retrieved)
		require.NoError(t, err, "Failed to unmarshal charge")

		assert.Equal(t, chargeID, retrieved["chargeID"])
		assert.Equal(t, "pending", retrieved["status"])
		assert.Equal(t, "Org2", retrieved["awayAgencyID"])
		assert.Equal(t, "Org1", retrieved["homeAgencyID"])
	})

	t.Run("GetCharge_ByHomeAgency", func(t *testing.T) {
		// Org1 (home agency) retrieves the charge
		result, err := org1Client.EvaluateTransaction("GetCharge", chargeID, "Org2", "Org1")
		require.NoError(t, err, "Failed to get charge as Org1")

		var retrieved map[string]interface{}
		err = json.Unmarshal(result, &retrieved)
		require.NoError(t, err)

		assert.Equal(t, chargeID, retrieved["chargeID"])
		assert.Equal(t, float64(4.75), retrieved["amount"])
	})

	t.Run("GetCharge_WithReversedAgencyOrder", func(t *testing.T) {
		// Collection naming is symmetric - should work with reversed order
		result, err := org1Client.EvaluateTransaction("GetCharge", chargeID, "Org1", "Org2")
		require.NoError(t, err, "Failed to get charge with reversed agency order")

		var retrieved map[string]interface{}
		err = json.Unmarshal(result, &retrieved)
		require.NoError(t, err)

		assert.Equal(t, chargeID, retrieved["chargeID"])
	})

	t.Run("UpdateChargeStatus_PendingToPosted", func(t *testing.T) {
		// Org1 (home agency) posts the charge
		_, err := org1Client.SubmitTransaction("UpdateChargeStatus", chargeID, "Org2", "Org1", "posted")
		require.NoError(t, err, "Failed to update charge status to posted")

		// Verify the update
		result, err := org1Client.EvaluateTransaction("GetCharge", chargeID, "Org2", "Org1")
		require.NoError(t, err)

		var updated map[string]interface{}
		err = json.Unmarshal(result, &updated)
		require.NoError(t, err)

		assert.Equal(t, "posted", updated["status"])
	})

	t.Run("UpdateChargeStatus_PostedToSettled", func(t *testing.T) {
		// Org1 marks the charge as settled
		_, err := org1Client.SubmitTransaction("UpdateChargeStatus", chargeID, "Org2", "Org1", "settled")
		require.NoError(t, err, "Failed to update charge status to settled")

		// Verify the update
		result, err := org1Client.EvaluateTransaction("GetCharge", chargeID, "Org2", "Org1")
		require.NoError(t, err)

		var updated map[string]interface{}
		err = json.Unmarshal(result, &updated)
		require.NoError(t, err)

		assert.Equal(t, "settled", updated["status"])
	})
}

// TestChargeValidation tests that invalid charges are rejected.
func TestChargeValidation(t *testing.T) {
	t.Run("RejectsDuplicateCharge", func(t *testing.T) {
		chargeID := uniqueID("CHG-DUP")
		charge := map[string]interface{}{
			"chargeID":        chargeID,
			"chargeType":      "toll_tag",
			"recordType":      "TB01",
			"protocol":        "niop",
			"awayAgencyID":    "Org2",
			"homeAgencyID":    "Org1",
			"tagSerialNumber": "TEST.000000001",
			"facilityID":      "SR73",
			"plaza":           "MAIN",
			"exitDateTime":    "2026-01-15T09:00:00Z",
			"vehicleClass":    2,
			"amount":          5.00,
			"fee":             0.05,
			"netAmount":       4.95,
			"status":          "pending",
		}
		chargeJSON, _ := json.Marshal(charge)

		// First creation should succeed
		_, err := org2Client.SubmitTransaction("CreateCharge", string(chargeJSON))
		require.NoError(t, err)

		// Second creation should fail
		_, err = org2Client.SubmitTransaction("CreateCharge", string(chargeJSON))
		require.Error(t, err, "Should reject duplicate charge")
		assert.Contains(t, err.Error(), "already exists")
	})

	t.Run("RejectsInvalidStatusTransition", func(t *testing.T) {
		chargeID := uniqueID("CHG-INV")
		charge := map[string]interface{}{
			"chargeID":        chargeID,
			"chargeType":      "toll_tag",
			"recordType":      "TB01",
			"protocol":        "niop",
			"awayAgencyID":    "Org2",
			"homeAgencyID":    "Org1",
			"tagSerialNumber": "TEST.000000002",
			"facilityID":      "SR73",
			"plaza":           "MAIN",
			"exitDateTime":    "2026-01-15T10:00:00Z",
			"vehicleClass":    2,
			"amount":          6.00,
			"fee":             0.05,
			"netAmount":       5.95,
			"status":          "pending",
		}
		chargeJSON, _ := json.Marshal(charge)

		_, err := org2Client.SubmitTransaction("CreateCharge", string(chargeJSON))
		require.NoError(t, err)

		// Try to go from pending directly to settled (invalid - must go through posted)
		_, err = org1Client.SubmitTransaction("UpdateChargeStatus", chargeID, "Org2", "Org1", "settled")
		require.Error(t, err, "Should reject invalid status transition")
		assert.Contains(t, err.Error(), "cannot transition")
	})

	t.Run("RejectsNonexistentCharge", func(t *testing.T) {
		_, err := org1Client.EvaluateTransaction("GetCharge", "NONEXISTENT-CHARGE", "Org2", "Org1")
		require.Error(t, err, "Should return error for nonexistent charge")
		assert.Contains(t, err.Error(), "not found")
	})
}

// TestGetChargesByAgencyPair tests the query functionality.
func TestGetChargesByAgencyPair(t *testing.T) {
	// Create multiple charges between Org1 and Org2
	chargeIDs := make([]string, 3)
	for i := 0; i < 3; i++ {
		chargeID := uniqueID("CHG-PAIR")
		chargeIDs[i] = chargeID

		charge := map[string]interface{}{
			"chargeID":        chargeID,
			"chargeType":      "toll_tag",
			"recordType":      "TB01",
			"protocol":        "niop",
			"awayAgencyID":    "Org2",
			"homeAgencyID":    "Org1",
			"tagSerialNumber": "TEST.000000003",
			"facilityID":      "SR73",
			"plaza":           "MAIN",
			"exitDateTime":    "2026-01-15T11:00:00Z",
			"vehicleClass":    2,
			"amount":          float64(i+1) * 5.00,
			"fee":             0.05,
			"netAmount":       float64(i+1)*5.00 - 0.05,
			"status":          "pending",
		}
		chargeJSON, _ := json.Marshal(charge)

		_, err := org2Client.SubmitTransaction("CreateCharge", string(chargeJSON))
		require.NoError(t, err)
	}

	t.Run("ReturnsChargesForAgencyPair", func(t *testing.T) {
		result, err := org1Client.EvaluateTransaction("GetChargesByAgencyPair", "Org2", "Org1")
		require.NoError(t, err)

		var charges []map[string]interface{}
		err = json.Unmarshal(result, &charges)
		require.NoError(t, err)

		// Should have at least the 3 charges we created
		assert.GreaterOrEqual(t, len(charges), 3, "Expected at least 3 charges")

		// Verify all returned charges are for the correct agency pair
		for _, c := range charges {
			away := c["awayAgencyID"].(string)
			home := c["homeAgencyID"].(string)
			// Collection is symmetric, so either order is valid
			validPair := (away == "Org1" && home == "Org2") || (away == "Org2" && home == "Org1")
			assert.True(t, validPair, "Charge should be for Org1/Org2 pair")
		}
	})

	t.Run("ReturnsChargesWithReversedAgencyOrder", func(t *testing.T) {
		// Query with reversed agency order - should return same results
		result, err := org1Client.EvaluateTransaction("GetChargesByAgencyPair", "Org1", "Org2")
		require.NoError(t, err)

		var charges []map[string]interface{}
		err = json.Unmarshal(result, &charges)
		require.NoError(t, err)

		assert.GreaterOrEqual(t, len(charges), 3)
	})
}
