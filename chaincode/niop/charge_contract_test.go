// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"testing"

	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func validCharge() *models.Charge {
	return &models.Charge{
		ChargeID:        "CHG-TEST-001",
		ChargeType:      "toll_tag",
		RecordType:      "TB01",
		Protocol:        "niop",
		AwayAgencyID:    "ORG2",
		HomeAgencyID:    "ORG1",
		TagSerialNumber: "TEST.000000001",
		FacilityID:      "SR73",
		Plaza:           "CATALINA",
		ExitDateTime:    "2026-01-15T08:30:00Z",
		VehicleClass:    2,
		Amount:          4.75,
		Fee:             0.05,
		NetAmount:       4.70,
		Status:          "pending",
	}
}

func TestCreateCharge(t *testing.T) {
	contract := &ChargeContract{}

	t.Run("creates valid charge", func(t *testing.T) {
		ctx := newMockContext()
		charge := validCharge()
		chargeJSON, _ := json.Marshal(charge)

		err := contract.CreateCharge(ctx, string(chargeJSON))
		require.NoError(t, err)

		// Verify private data was written (collection is charges_ORG1_ORG2, alphabetically sorted)
		bytes, err := ctx.stub.GetPrivateData("charges_ORG1_ORG2", "CHARGE_CHG-TEST-001")
		require.NoError(t, err)
		require.NotNil(t, bytes)

		var stored models.Charge
		err = json.Unmarshal(bytes, &stored)
		require.NoError(t, err)
		assert.Equal(t, "CHG-TEST-001", stored.ChargeID)
		assert.Equal(t, "pending", stored.Status)
		assert.NotEmpty(t, stored.CreatedAt)
	})

	t.Run("rejects duplicate charge", func(t *testing.T) {
		ctx := newMockContext()
		charge := validCharge()
		chargeJSON, _ := json.Marshal(charge)

		err := contract.CreateCharge(ctx, string(chargeJSON))
		require.NoError(t, err)

		err = contract.CreateCharge(ctx, string(chargeJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "already exists")
	})

	t.Run("rejects invalid JSON", func(t *testing.T) {
		ctx := newMockContext()
		err := contract.CreateCharge(ctx, "not valid json")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "failed to parse")
	})

	t.Run("rejects same agency for away and home", func(t *testing.T) {
		ctx := newMockContext()
		charge := validCharge()
		charge.HomeAgencyID = "ORG2" // same as away
		chargeJSON, _ := json.Marshal(charge)

		err := contract.CreateCharge(ctx, string(chargeJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "must be different")
	})

	t.Run("rejects tag charge without tag serial number", func(t *testing.T) {
		ctx := newMockContext()
		charge := validCharge()
		charge.TagSerialNumber = "" // missing for TB01
		chargeJSON, _ := json.Marshal(charge)

		err := contract.CreateCharge(ctx, string(chargeJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "tagSerialNumber is required")
	})

	t.Run("rejects video charge without plate", func(t *testing.T) {
		ctx := newMockContext()
		charge := validCharge()
		charge.RecordType = "VB01"
		charge.TagSerialNumber = ""
		// missing plate info
		chargeJSON, _ := json.Marshal(charge)

		err := contract.CreateCharge(ctx, string(chargeJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "plateNumber is required")
	})
}

func TestGetCharge(t *testing.T) {
	contract := &ChargeContract{}

	t.Run("retrieves existing charge", func(t *testing.T) {
		ctx := newMockContext()
		charge := validCharge()
		chargeJSON, _ := json.Marshal(charge)
		_ = contract.CreateCharge(ctx, string(chargeJSON))

		result, err := contract.GetCharge(ctx, "CHG-TEST-001", "ORG2", "ORG1")
		require.NoError(t, err)
		require.NotNil(t, result)
		assert.Equal(t, "CHG-TEST-001", result.ChargeID)
		assert.Equal(t, "ORG2", result.AwayAgencyID)
		assert.Equal(t, "ORG1", result.HomeAgencyID)
	})

	t.Run("retrieves charge with reversed agency order", func(t *testing.T) {
		ctx := newMockContext()
		charge := validCharge()
		chargeJSON, _ := json.Marshal(charge)
		_ = contract.CreateCharge(ctx, string(chargeJSON))

		// Pass agencies in reverse order - should still work
		result, err := contract.GetCharge(ctx, "CHG-TEST-001", "ORG1", "ORG2")
		require.NoError(t, err)
		require.NotNil(t, result)
		assert.Equal(t, "CHG-TEST-001", result.ChargeID)
	})

	t.Run("returns error for nonexistent charge", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetCharge(ctx, "NONEXISTENT", "ORG2", "ORG1")
		require.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "not found")
	})
}

func TestUpdateChargeStatus(t *testing.T) {
	contract := &ChargeContract{}

	t.Run("updates status with valid transition", func(t *testing.T) {
		ctx := newMockContext()
		charge := validCharge()
		chargeJSON, _ := json.Marshal(charge)
		_ = contract.CreateCharge(ctx, string(chargeJSON))

		// pending -> posted is allowed
		err := contract.UpdateChargeStatus(ctx, "CHG-TEST-001", "ORG2", "ORG1", "posted")
		require.NoError(t, err)

		result, err := contract.GetCharge(ctx, "CHG-TEST-001", "ORG2", "ORG1")
		require.NoError(t, err)
		assert.Equal(t, "posted", result.Status)
	})

	t.Run("rejects invalid status transition", func(t *testing.T) {
		ctx := newMockContext()
		charge := validCharge()
		chargeJSON, _ := json.Marshal(charge)
		_ = contract.CreateCharge(ctx, string(chargeJSON))

		// pending -> settled is NOT allowed (must go through posted)
		err := contract.UpdateChargeStatus(ctx, "CHG-TEST-001", "ORG2", "ORG1", "settled")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "cannot transition")
	})

	t.Run("rejects invalid status value", func(t *testing.T) {
		ctx := newMockContext()
		charge := validCharge()
		chargeJSON, _ := json.Marshal(charge)
		_ = contract.CreateCharge(ctx, string(chargeJSON))

		err := contract.UpdateChargeStatus(ctx, "CHG-TEST-001", "ORG2", "ORG1", "bad_status")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid target status")
	})

	t.Run("returns error for nonexistent charge", func(t *testing.T) {
		ctx := newMockContext()

		err := contract.UpdateChargeStatus(ctx, "NONEXISTENT", "ORG2", "ORG1", "posted")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "not found")
	})
}

func TestGetChargesByAgencyPair(t *testing.T) {
	contract := &ChargeContract{}

	t.Run("returns empty list when no charges", func(t *testing.T) {
		ctx := newEnhancedMockContext()

		result, err := contract.GetChargesByAgencyPair(ctx, "ORG2", "ORG1")
		require.NoError(t, err)
		assert.Empty(t, result)
	})

	t.Run("returns charges for agency pair", func(t *testing.T) {
		ctx := newEnhancedMockContext()

		// Create multiple charges
		charge1 := validCharge()
		charge1JSON, _ := json.Marshal(charge1)
		_ = contract.CreateCharge(ctx, string(charge1JSON))

		charge2 := validCharge()
		charge2.ChargeID = "CHG-TEST-002"
		charge2JSON, _ := json.Marshal(charge2)
		_ = contract.CreateCharge(ctx, string(charge2JSON))

		result, err := contract.GetChargesByAgencyPair(ctx, "ORG2", "ORG1")
		require.NoError(t, err)
		assert.Len(t, result, 2)
	})

	t.Run("returns charges regardless of agency order", func(t *testing.T) {
		ctx := newEnhancedMockContext()

		charge := validCharge()
		chargeJSON, _ := json.Marshal(charge)
		_ = contract.CreateCharge(ctx, string(chargeJSON))

		// Query with reversed agency order
		result, err := contract.GetChargesByAgencyPair(ctx, "ORG1", "ORG2")
		require.NoError(t, err)
		assert.Len(t, result, 1)
		assert.Equal(t, "CHG-TEST-001", result[0].ChargeID)
	})
}

func TestChargeCollectionNameSymmetry(t *testing.T) {
	// This tests a critical business rule: collection names must be symmetric
	// so both agencies can find the same data regardless of who queries

	charge1 := &models.Charge{
		AwayAgencyID: "ORG2",
		HomeAgencyID: "ORG1",
	}

	charge2 := &models.Charge{
		AwayAgencyID: "ORG1",
		HomeAgencyID: "ORG2",
	}

	assert.Equal(t, charge1.CollectionName(), charge2.CollectionName())
	assert.Equal(t, "charges_ORG1_ORG2", charge1.CollectionName())
}
