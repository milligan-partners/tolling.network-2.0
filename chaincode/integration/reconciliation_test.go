// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

//go:build integration

package integration

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestChargeReconciliationWorkflow tests the complete workflow from
// charge creation to reconciliation posting.
func TestChargeReconciliationWorkflow(t *testing.T) {
	chargeID := uniqueID("CHG-RECON")
	reconID := uniqueID("RECON")

	// Step 1: Create a charge
	charge := map[string]interface{}{
		"chargeID":        chargeID,
		"chargeType":      "toll_tag",
		"recordType":      "TB01",
		"protocol":        "niop",
		"awayAgencyID":    "Org2",
		"homeAgencyID":    "Org1",
		"tagSerialNumber": "TEST.RECON.001",
		"facilityID":      "SR73",
		"plaza":           "RECON-TEST",
		"exitDateTime":    "2026-01-15T15:00:00Z",
		"vehicleClass":    2,
		"amount":          15.00,
		"fee":             0.15,
		"netAmount":       14.85,
		"status":          "pending",
	}
	chargeJSON, _ := json.Marshal(charge)

	t.Run("Step1_CreateCharge", func(t *testing.T) {
		_, err := org2Client.SubmitTransaction("CreateCharge", string(chargeJSON))
		require.NoError(t, err, "Failed to create charge")
	})

	// Step 2: Home agency creates reconciliation
	recon := map[string]interface{}{
		"reconciliationID":   reconID,
		"chargeID":           chargeID,
		"homeAgencyID":       "Org1",
		"postingDisposition": "P", // Posted
		"postedAmount":       15.00,
		"postedDateTime":     "2026-01-15T16:00:00Z",
		"adjustmentCount":    0,
		"flatFee":            0.15,
		"percentFee":         0.0,
	}
	reconJSON, _ := json.Marshal(recon)

	t.Run("Step2_CreateReconciliation", func(t *testing.T) {
		_, err := org1Client.SubmitTransaction("CreateReconciliation", string(reconJSON))
		require.NoError(t, err, "Failed to create reconciliation")
	})

	t.Run("Step3_GetReconciliationByChargeID", func(t *testing.T) {
		result, err := org1Client.EvaluateTransaction("GetReconciliation", chargeID)
		require.NoError(t, err, "Failed to get reconciliation")

		var retrieved map[string]interface{}
		err = json.Unmarshal(result, &retrieved)
		require.NoError(t, err)

		assert.Equal(t, reconID, retrieved["reconciliationID"])
		assert.Equal(t, chargeID, retrieved["chargeID"])
		assert.Equal(t, "P", retrieved["postingDisposition"])
		assert.Equal(t, float64(15.00), retrieved["postedAmount"])
	})

	t.Run("Step4_RejectDuplicateReconciliation", func(t *testing.T) {
		// Try to create another reconciliation for the same charge
		dupeRecon := map[string]interface{}{
			"reconciliationID":   uniqueID("RECON-DUPE"),
			"chargeID":           chargeID, // Same charge ID
			"homeAgencyID":       "Org1",
			"postingDisposition": "P",
			"postedAmount":       15.00,
			"postedDateTime":     "2026-01-15T17:00:00Z",
			"adjustmentCount":    0,
			"flatFee":            0.15,
			"percentFee":         0.0,
		}
		dupeJSON, _ := json.Marshal(dupeRecon)

		_, err := org1Client.SubmitTransaction("CreateReconciliation", string(dupeJSON))
		require.Error(t, err, "Should reject duplicate reconciliation for same charge")
		assert.Contains(t, err.Error(), "already exists")
	})
}

// TestReconciliationDispositions tests different posting disposition codes.
func TestReconciliationDispositions(t *testing.T) {
	dispositions := []struct {
		code        string
		description string
	}{
		{"P", "Posted successfully"},
		{"D", "Duplicate transaction"},
		{"I", "Invalid tag or plate"},
		{"N", "Not posted (general)"},
		{"C", "Tag/plate not on file"},
		{"O", "Transaction too old"},
	}

	for _, disp := range dispositions {
		t.Run("Disposition_"+disp.code, func(t *testing.T) {
			chargeID := uniqueID("CHG-DISP-" + disp.code)
			reconID := uniqueID("RECON-DISP-" + disp.code)

			// Create charge
			charge := map[string]interface{}{
				"chargeID":        chargeID,
				"chargeType":      "toll_tag",
				"recordType":      "TB01",
				"protocol":        "niop",
				"awayAgencyID":    "Org2",
				"homeAgencyID":    "Org1",
				"tagSerialNumber": "TEST.DISP." + disp.code,
				"facilityID":      "SR73",
				"plaza":           "DISP-" + disp.code,
				"exitDateTime":    "2026-01-15T18:00:00Z",
				"vehicleClass":    2,
				"amount":          10.00,
				"fee":             0.10,
				"netAmount":       9.90,
				"status":          "pending",
			}
			chargeJSON, _ := json.Marshal(charge)
			_, err := org2Client.SubmitTransaction("CreateCharge", string(chargeJSON))
			require.NoError(t, err)

			// Create reconciliation with specific disposition
			recon := map[string]interface{}{
				"reconciliationID":   reconID,
				"chargeID":           chargeID,
				"homeAgencyID":       "Org1",
				"postingDisposition": disp.code,
				"postedAmount":       10.00,
				"postedDateTime":     "2026-01-15T18:30:00Z",
				"adjustmentCount":    0,
				"flatFee":            0.10,
				"percentFee":         0.0,
			}
			reconJSON, _ := json.Marshal(recon)
			_, err = org1Client.SubmitTransaction("CreateReconciliation", string(reconJSON))
			require.NoError(t, err, "Failed to create reconciliation with disposition %s", disp.code)

			// Verify the disposition was stored correctly
			result, err := org1Client.EvaluateTransaction("GetReconciliation", chargeID)
			require.NoError(t, err)

			var retrieved map[string]interface{}
			json.Unmarshal(result, &retrieved)
			assert.Equal(t, disp.code, retrieved["postingDisposition"])
		})
	}
}

// TestReconciliationValidation tests that invalid reconciliations are rejected.
func TestReconciliationValidation(t *testing.T) {
	t.Run("RejectsInvalidDisposition", func(t *testing.T) {
		chargeID := uniqueID("CHG-INV-DISP")

		// Create charge first
		charge := map[string]interface{}{
			"chargeID":        chargeID,
			"chargeType":      "toll_tag",
			"recordType":      "TB01",
			"protocol":        "niop",
			"awayAgencyID":    "Org2",
			"homeAgencyID":    "Org1",
			"tagSerialNumber": "TEST.INV.DISP",
			"facilityID":      "SR73",
			"plaza":           "INV-DISP",
			"exitDateTime":    "2026-01-15T19:00:00Z",
			"vehicleClass":    2,
			"amount":          5.00,
			"fee":             0.05,
			"netAmount":       4.95,
			"status":          "pending",
		}
		chargeJSON, _ := json.Marshal(charge)
		_, err := org2Client.SubmitTransaction("CreateCharge", string(chargeJSON))
		require.NoError(t, err)

		// Try to create reconciliation with invalid disposition
		recon := map[string]interface{}{
			"reconciliationID":   uniqueID("RECON-INV"),
			"chargeID":           chargeID,
			"homeAgencyID":       "Org1",
			"postingDisposition": "X", // Invalid disposition code
			"postedAmount":       5.00,
			"postedDateTime":     "2026-01-15T19:30:00Z",
			"adjustmentCount":    0,
			"flatFee":            0.05,
			"percentFee":         0.0,
		}
		reconJSON, _ := json.Marshal(recon)

		_, err = org1Client.SubmitTransaction("CreateReconciliation", string(reconJSON))
		require.Error(t, err, "Should reject invalid disposition code")
		assert.Contains(t, err.Error(), "invalid postingDisposition")
	})
}
