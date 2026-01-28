// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

//go:build integration

package integration

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestPrivateDataIsolation verifies that private data collections properly
// isolate data between agency pairs. Only the two agencies in a bilateral
// relationship should be able to access their shared collection.
func TestPrivateDataIsolation(t *testing.T) {
	// Create a charge between Org1 and Org2
	chargeID := uniqueID("CHG-PRIV")
	charge := map[string]interface{}{
		"chargeID":        chargeID,
		"chargeType":      "toll_tag",
		"recordType":      "TB01",
		"protocol":        "niop",
		"awayAgencyID":    "Org2",
		"homeAgencyID":    "Org1",
		"tagSerialNumber": "TEST.PRIV.001",
		"facilityID":      "SR73",
		"plaza":           "PRIVATE-TEST",
		"exitDateTime":    "2026-01-15T12:00:00Z",
		"vehicleClass":    2,
		"amount":          7.50,
		"fee":             0.05,
		"netAmount":       7.45,
		"status":          "pending",
	}
	chargeJSON, _ := json.Marshal(charge)

	// Org2 creates the charge
	_, err := org2Client.SubmitTransaction("CreateCharge", string(chargeJSON))
	require.NoError(t, err, "Failed to create charge for isolation test")

	t.Run("Org1_CanAccess_Org1Org2Collection", func(t *testing.T) {
		// Org1 is part of the bilateral relationship
		result, err := org1Client.EvaluateTransaction("GetCharge", chargeID, "Org2", "Org1")
		require.NoError(t, err, "Org1 should be able to access charges_Org1_Org2 collection")

		var retrieved map[string]interface{}
		err = json.Unmarshal(result, &retrieved)
		require.NoError(t, err)
		assert.Equal(t, chargeID, retrieved["chargeID"])
	})

	t.Run("Org2_CanAccess_Org1Org2Collection", func(t *testing.T) {
		// Org2 is part of the bilateral relationship
		result, err := org2Client.EvaluateTransaction("GetCharge", chargeID, "Org2", "Org1")
		require.NoError(t, err, "Org2 should be able to access charges_Org1_Org2 collection")

		var retrieved map[string]interface{}
		err = json.Unmarshal(result, &retrieved)
		require.NoError(t, err)
		assert.Equal(t, chargeID, retrieved["chargeID"])
	})

	t.Run("Org3_CannotAccess_Org1Org2Collection", func(t *testing.T) {
		// Org3 is NOT part of the Org1/Org2 bilateral relationship
		// This should fail because Org3 doesn't have access to the collection
		_, err := org3Client.EvaluateTransaction("GetCharge", chargeID, "Org2", "Org1")
		// The error might be about collection access or the data simply not being found
		// Either way, Org3 should not get the data
		assert.Error(t, err, "Org3 should NOT be able to access charges_Org1_Org2 collection")
	})

	t.Run("Org4_CannotAccess_Org1Org2Collection", func(t *testing.T) {
		// Org4 is also NOT part of the Org1/Org2 bilateral relationship
		_, err := org4Client.EvaluateTransaction("GetCharge", chargeID, "Org2", "Org1")
		assert.Error(t, err, "Org4 should NOT be able to access charges_Org1_Org2 collection")
	})
}

// TestCollectionNamingSymmetry verifies that collection names are symmetric,
// meaning both agencies in a pair resolve to the same collection regardless
// of the order they're specified.
func TestCollectionNamingSymmetry(t *testing.T) {
	// Create a charge where Org3 is the away agency and Org4 is the home agency
	chargeID := uniqueID("CHG-SYM")
	charge := map[string]interface{}{
		"chargeID":        chargeID,
		"chargeType":      "toll_tag",
		"recordType":      "TB01",
		"protocol":        "niop",
		"awayAgencyID":    "Org3",
		"homeAgencyID":    "Org4",
		"tagSerialNumber": "TEST.SYM.001",
		"facilityID":      "I405",
		"plaza":           "SYMMETRY-TEST",
		"exitDateTime":    "2026-01-15T13:00:00Z",
		"vehicleClass":    2,
		"amount":          8.00,
		"fee":             0.05,
		"netAmount":       7.95,
		"status":          "pending",
	}
	chargeJSON, _ := json.Marshal(charge)

	// Org3 creates the charge
	_, err := org3Client.SubmitTransaction("CreateCharge", string(chargeJSON))
	require.NoError(t, err)

	t.Run("AccessWithOriginalOrder", func(t *testing.T) {
		// Access with original order: away=Org3, home=Org4
		result, err := org4Client.EvaluateTransaction("GetCharge", chargeID, "Org3", "Org4")
		require.NoError(t, err)

		var retrieved map[string]interface{}
		err = json.Unmarshal(result, &retrieved)
		require.NoError(t, err)
		assert.Equal(t, chargeID, retrieved["chargeID"])
	})

	t.Run("AccessWithReversedOrder", func(t *testing.T) {
		// Access with reversed order: Org4, Org3
		// Collection naming should resolve to the same collection
		result, err := org3Client.EvaluateTransaction("GetCharge", chargeID, "Org4", "Org3")
		require.NoError(t, err, "Should access same data with reversed agency order")

		var retrieved map[string]interface{}
		err = json.Unmarshal(result, &retrieved)
		require.NoError(t, err)
		assert.Equal(t, chargeID, retrieved["chargeID"])
	})
}

// TestMultipleBilateralCollections verifies that multiple bilateral relationships
// can coexist and remain isolated from each other.
func TestMultipleBilateralCollections(t *testing.T) {
	// Create charges in different bilateral collections

	// Charge between Org1 and Org2
	charge12ID := uniqueID("CHG-12")
	charge12 := map[string]interface{}{
		"chargeID":        charge12ID,
		"chargeType":      "toll_tag",
		"recordType":      "TB01",
		"protocol":        "niop",
		"awayAgencyID":    "Org1",
		"homeAgencyID":    "Org2",
		"tagSerialNumber": "TEST.MULTI.012",
		"facilityID":      "SR73",
		"plaza":           "MULTI-12",
		"exitDateTime":    "2026-01-15T14:00:00Z",
		"vehicleClass":    2,
		"amount":          10.00,
		"fee":             0.10,
		"netAmount":       9.90,
		"status":          "pending",
	}
	charge12JSON, _ := json.Marshal(charge12)
	_, err := org1Client.SubmitTransaction("CreateCharge", string(charge12JSON))
	require.NoError(t, err)

	// Charge between Org3 and Org4
	charge34ID := uniqueID("CHG-34")
	charge34 := map[string]interface{}{
		"chargeID":        charge34ID,
		"chargeType":      "toll_tag",
		"recordType":      "TB01",
		"protocol":        "niop",
		"awayAgencyID":    "Org3",
		"homeAgencyID":    "Org4",
		"tagSerialNumber": "TEST.MULTI.034",
		"facilityID":      "I405",
		"plaza":           "MULTI-34",
		"exitDateTime":    "2026-01-15T14:30:00Z",
		"vehicleClass":    2,
		"amount":          12.00,
		"fee":             0.10,
		"netAmount":       11.90,
		"status":          "pending",
	}
	charge34JSON, _ := json.Marshal(charge34)
	_, err = org3Client.SubmitTransaction("CreateCharge", string(charge34JSON))
	require.NoError(t, err)

	t.Run("Org1Org2_CanAccess_TheirCharge", func(t *testing.T) {
		result, err := org2Client.EvaluateTransaction("GetCharge", charge12ID, "Org1", "Org2")
		require.NoError(t, err)

		var retrieved map[string]interface{}
		json.Unmarshal(result, &retrieved)
		assert.Equal(t, charge12ID, retrieved["chargeID"])
	})

	t.Run("Org3Org4_CanAccess_TheirCharge", func(t *testing.T) {
		result, err := org4Client.EvaluateTransaction("GetCharge", charge34ID, "Org3", "Org4")
		require.NoError(t, err)

		var retrieved map[string]interface{}
		json.Unmarshal(result, &retrieved)
		assert.Equal(t, charge34ID, retrieved["chargeID"])
	})

	t.Run("Org1Org2_CannotAccess_Org3Org4Charge", func(t *testing.T) {
		// Org1 tries to access the Org3/Org4 charge
		_, err := org1Client.EvaluateTransaction("GetCharge", charge34ID, "Org3", "Org4")
		assert.Error(t, err, "Org1 should not access Org3/Org4 collection")
	})

	t.Run("Org3Org4_CannotAccess_Org1Org2Charge", func(t *testing.T) {
		// Org3 tries to access the Org1/Org2 charge
		_, err := org3Client.EvaluateTransaction("GetCharge", charge12ID, "Org1", "Org2")
		assert.Error(t, err, "Org3 should not access Org1/Org2 collection")
	})
}
