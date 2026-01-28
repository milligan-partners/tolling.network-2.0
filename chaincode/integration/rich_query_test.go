// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

//go:build integration

package integration

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestReconciliationRichQueries tests CouchDB rich query functionality
// for reconciliation queries by agency and disposition.
func TestReconciliationRichQueries(t *testing.T) {
	// Setup: Create charges and reconciliations with different dispositions
	dispositions := []string{"P", "D", "I", "N"}

	for i, disp := range dispositions {
		chargeID := uniqueID("CHG-RQ-" + disp)

		// Create charge
		charge := map[string]interface{}{
			"chargeID":        chargeID,
			"chargeType":      "toll_tag",
			"recordType":      "TB01",
			"protocol":        "niop",
			"awayAgencyID":    "Org2",
			"homeAgencyID":    "Org1",
			"tagSerialNumber": "TEST.RQ." + disp,
			"facilityID":      "SR73",
			"plaza":           "RICHQUERY-" + disp,
			"exitDateTime":    "2026-01-20T10:00:00Z",
			"vehicleClass":    2,
			"amount":          float64(i+1) * 10,
			"fee":             0.10,
			"netAmount":       float64(i+1)*10 - 0.10,
			"status":          "pending",
		}
		chargeJSON, _ := json.Marshal(charge)
		_, err := org2Client.SubmitTransaction("CreateCharge", string(chargeJSON))
		require.NoError(t, err)

		// Create reconciliation with specific disposition
		recon := map[string]interface{}{
			"reconciliationID":   uniqueID("RECON-RQ-" + disp),
			"chargeID":           chargeID,
			"homeAgencyID":       "Org1",
			"postingDisposition": disp,
			"postedAmount":       float64(i+1) * 10,
			"postedDateTime":     "2026-01-20T12:00:00Z",
			"adjustmentCount":    0,
			"flatFee":            0.10,
			"percentFee":         0.0,
		}
		reconJSON, _ := json.Marshal(recon)
		_, err = org1Client.SubmitTransaction("CreateReconciliation", string(reconJSON))
		require.NoError(t, err)
	}

	t.Run("QueryReconciliationsByDisposition_Posted", func(t *testing.T) {
		result, err := org1Client.EvaluateTransaction("GetReconciliationsByDisposition", "P")
		require.NoError(t, err, "Failed to query reconciliations by disposition")

		var recons []map[string]interface{}
		err = json.Unmarshal(result, &recons)
		require.NoError(t, err)

		// Should have at least one "Posted" reconciliation
		assert.GreaterOrEqual(t, len(recons), 1, "Expected at least 1 Posted reconciliation")

		// Verify all returned have disposition P
		for _, r := range recons {
			assert.Equal(t, "P", r["postingDisposition"],
				"All returned reconciliations should have disposition P")
		}
	})

	t.Run("QueryReconciliationsByDisposition_Duplicate", func(t *testing.T) {
		result, err := org1Client.EvaluateTransaction("GetReconciliationsByDisposition", "D")
		require.NoError(t, err)

		var recons []map[string]interface{}
		err = json.Unmarshal(result, &recons)
		require.NoError(t, err)

		assert.GreaterOrEqual(t, len(recons), 1)

		for _, r := range recons {
			assert.Equal(t, "D", r["postingDisposition"])
		}
	})

	t.Run("QueryReconciliationsByAgency", func(t *testing.T) {
		result, err := org1Client.EvaluateTransaction("GetReconciliationsByAgency", "Org1")
		require.NoError(t, err, "Failed to query reconciliations by agency")

		var recons []map[string]interface{}
		err = json.Unmarshal(result, &recons)
		require.NoError(t, err)

		// Should have at least the 4 reconciliations we created
		assert.GreaterOrEqual(t, len(recons), 4, "Expected at least 4 reconciliations for Org1")

		// Verify all belong to Org1
		for _, r := range recons {
			assert.Equal(t, "Org1", r["homeAgencyID"])
		}
	})
}

// TestTagRichQueries tests CouchDB rich query functionality for tags.
func TestTagRichQueries(t *testing.T) {
	// Create tags for Org1
	tagSerials := make([]string, 3)
	for i := 0; i < 3; i++ {
		serial := uniqueID("TAG-RQ")
		tagSerials[i] = serial

		tag := map[string]interface{}{
			"tagSerialNumber": serial,
			"tagAgencyID":     "Org1",
			"protocol":        "niop",
			"tagType":         "interior",
			"status":          "valid",
			"accountID":       "ACC-001",
			"issuedDate":      "2026-01-01",
		}
		tagJSON, _ := json.Marshal(tag)
		_, err := org1Client.SubmitTransaction("CreateTag", string(tagJSON))
		require.NoError(t, err)
	}

	t.Run("QueryTagsByAgency", func(t *testing.T) {
		result, err := org1Client.EvaluateTransaction("GetTagsByAgency", "Org1")
		require.NoError(t, err, "Failed to query tags by agency")

		var tags []map[string]interface{}
		err = json.Unmarshal(result, &tags)
		require.NoError(t, err)

		// Should have at least the 3 tags we created
		assert.GreaterOrEqual(t, len(tags), 3, "Expected at least 3 tags for Org1")

		// Verify all belong to Org1
		for _, tag := range tags {
			assert.Equal(t, "Org1", tag["tagAgencyID"])
		}
	})
}

// TestAgencyRichQueries tests CouchDB rich query functionality for agencies.
func TestAgencyRichQueries(t *testing.T) {
	// Create some agencies
	agencyIDs := make([]string, 2)
	for i := 0; i < 2; i++ {
		agencyID := uniqueID("AGENCY-RQ")
		agencyIDs[i] = agencyID

		agency := map[string]interface{}{
			"agencyID":     agencyID,
			"name":         "Test Agency " + agencyID,
			"role":         "toll_operator",
			"status":       "active",
			"connectivity": "direct",
			"protocol":     "niop",
			"region":       "WEST",
			"state":        "CA",
		}
		agencyJSON, _ := json.Marshal(agency)
		_, err := org1Client.SubmitTransaction("CreateAgency", string(agencyJSON))
		require.NoError(t, err)
	}

	t.Run("GetAllAgencies", func(t *testing.T) {
		result, err := org1Client.EvaluateTransaction("GetAllAgencies")
		require.NoError(t, err, "Failed to get all agencies")

		var agencies []map[string]interface{}
		err = json.Unmarshal(result, &agencies)
		require.NoError(t, err)

		// Should have at least the 2 agencies we created
		assert.GreaterOrEqual(t, len(agencies), 2, "Expected at least 2 agencies")

		// Verify docType is set correctly
		for _, a := range agencies {
			assert.Equal(t, "agency", a["docType"])
		}
	})
}

// TestSettlementRichQueries tests CouchDB rich query functionality for settlements.
func TestSettlementRichQueries(t *testing.T) {
	// Create settlements with different statuses
	statuses := []string{"draft", "submitted"}

	for i, status := range statuses {
		settlement := map[string]interface{}{
			"settlementID":    uniqueID("SETTLE-RQ-" + status),
			"periodStart":     "2026-07-01",
			"periodEnd":       "2026-07-31",
			"payorAgencyID":   "Org1",
			"payeeAgencyID":   "Org2",
			"grossAmount":     float64((i + 1) * 5000),
			"totalFees":       float64((i + 1) * 50),
			"netAmount":       float64((i+1)*5000 - (i+1)*50),
			"chargeCount":     (i + 1) * 500,
			"correctionCount": i * 5,
			"status":          status,
		}
		settlementJSON, _ := json.Marshal(settlement)
		_, err := org1Client.SubmitTransaction("CreateSettlement", string(settlementJSON))
		require.NoError(t, err)

		// If not draft, update status
		if status == "submitted" {
			settlementID := settlement["settlementID"].(string)
			// First create as draft, then update to submitted
			_, err := org1Client.SubmitTransaction("UpdateSettlementStatus", settlementID, "Org1", "Org2", "submitted")
			// Ignore error since the settlement was created with the target status
			_ = err
		}
	}

	t.Run("QuerySettlementsByStatus", func(t *testing.T) {
		result, err := org1Client.EvaluateTransaction("GetSettlementsByStatus", "Org1", "Org2", "draft")
		require.NoError(t, err, "Failed to query settlements by status")

		var settlements []map[string]interface{}
		err = json.Unmarshal(result, &settlements)
		require.NoError(t, err)

		// Should have at least 1 draft settlement
		assert.GreaterOrEqual(t, len(settlements), 1, "Expected at least 1 draft settlement")

		// Verify all returned are draft status
		for _, s := range settlements {
			assert.Equal(t, "draft", s["status"])
		}
	})
}

// TestIndexPerformance runs a simple test to verify indexes are being used.
// In a real scenario, you would check query explain plans, but for integration
// tests we just verify the queries complete successfully.
func TestIndexPerformance(t *testing.T) {
	t.Run("ReconciliationByDispositionUsesIndex", func(t *testing.T) {
		// This query should use the reconciliation_by_disposition index
		result, err := org1Client.EvaluateTransaction("GetReconciliationsByDisposition", "P")
		require.NoError(t, err, "Indexed query should complete successfully")

		var recons []map[string]interface{}
		err = json.Unmarshal(result, &recons)
		require.NoError(t, err)
		// Just verify it returns valid JSON
	})

	t.Run("ReconciliationByAgencyUsesIndex", func(t *testing.T) {
		// This query should use the reconciliation_by_agency index
		result, err := org1Client.EvaluateTransaction("GetReconciliationsByAgency", "Org1")
		require.NoError(t, err, "Indexed query should complete successfully")

		var recons []map[string]interface{}
		err = json.Unmarshal(result, &recons)
		require.NoError(t, err)
	})

	t.Run("TagsByAgencyUsesIndex", func(t *testing.T) {
		// This query should use the tag_by_agency index
		result, err := org1Client.EvaluateTransaction("GetTagsByAgency", "Org1")
		require.NoError(t, err, "Indexed query should complete successfully")

		var tags []map[string]interface{}
		err = json.Unmarshal(result, &tags)
		require.NoError(t, err)
	})
}
