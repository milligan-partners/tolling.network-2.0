// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"testing"

	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// newMockContext is defined in mock_stub_test.go as newEnhancedMockContext.
// We alias it here for backwards compatibility with existing tests.
func newMockContext() *enhancedMockContext {
	return newEnhancedMockContext()
}

func validAgency() *models.Agency {
	return &models.Agency{
		AgencyID:         "ORG1",
		Name:             "Transportation Corridor Agencies",
		Consortium:       []string{"WRTO"},
		State:            "CA",
		Role:             "toll_operator",
		ConnectivityMode: "direct",
		Status:           "active",
		Capabilities:     []string{"toll"},
		ProtocolSupport:  []string{"ctoc_rev_a"},
	}
}

func TestCreateAgency(t *testing.T) {
	contract := &AgencyContract{}

	t.Run("creates valid agency", func(t *testing.T) {
		ctx := newMockContext()
		agency := validAgency()
		agencyJSON, _ := json.Marshal(agency)

		err := contract.CreateAgency(ctx, string(agencyJSON))
		require.NoError(t, err)

		// Verify state was written
		bytes, err := ctx.stub.GetState("AGENCY_ORG1")
		require.NoError(t, err)
		require.NotNil(t, bytes)

		var stored models.Agency
		err = json.Unmarshal(bytes, &stored)
		require.NoError(t, err)
		assert.Equal(t, "ORG1", stored.AgencyID)
		assert.Equal(t, "Transportation Corridor Agencies", stored.Name)
		assert.NotEmpty(t, stored.CreatedAt)
		assert.NotEmpty(t, stored.UpdatedAt)
	})

	t.Run("rejects duplicate agency", func(t *testing.T) {
		ctx := newMockContext()
		agency := validAgency()
		agencyJSON, _ := json.Marshal(agency)

		// Create first time
		err := contract.CreateAgency(ctx, string(agencyJSON))
		require.NoError(t, err)

		// Try to create again
		err = contract.CreateAgency(ctx, string(agencyJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "already exists")
	})

	t.Run("rejects invalid JSON", func(t *testing.T) {
		ctx := newMockContext()
		err := contract.CreateAgency(ctx, "not valid json")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "failed to parse")
	})

	t.Run("rejects missing required fields", func(t *testing.T) {
		ctx := newMockContext()
		agency := &models.Agency{
			AgencyID: "", // missing
			Name:     "Test Agency",
		}
		agencyJSON, _ := json.Marshal(agency)

		err := contract.CreateAgency(ctx, string(agencyJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "validation failed")
		assert.Contains(t, err.Error(), "agencyID is required")
	})

	t.Run("rejects invalid role", func(t *testing.T) {
		ctx := newMockContext()
		agency := validAgency()
		agency.Role = "invalid_role"
		agencyJSON, _ := json.Marshal(agency)

		err := contract.CreateAgency(ctx, string(agencyJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid role")
	})
}

func TestGetAgency(t *testing.T) {
	contract := &AgencyContract{}

	t.Run("retrieves existing agency", func(t *testing.T) {
		ctx := newMockContext()
		agency := validAgency()
		agencyJSON, _ := json.Marshal(agency)
		_ = contract.CreateAgency(ctx, string(agencyJSON))

		result, err := contract.GetAgency(ctx, "ORG1")
		require.NoError(t, err)
		require.NotNil(t, result)
		assert.Equal(t, "ORG1", result.AgencyID)
		assert.Equal(t, "Transportation Corridor Agencies", result.Name)
	})

	t.Run("returns error for nonexistent agency", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetAgency(ctx, "NONEXISTENT")
		require.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "not found")
	})
}

func TestUpdateAgencyStatus(t *testing.T) {
	contract := &AgencyContract{}

	t.Run("updates status successfully", func(t *testing.T) {
		ctx := newMockContext()
		agency := validAgency()
		agencyJSON, _ := json.Marshal(agency)
		_ = contract.CreateAgency(ctx, string(agencyJSON))

		err := contract.UpdateAgencyStatus(ctx, "ORG1", "suspended")
		require.NoError(t, err)

		result, err := contract.GetAgency(ctx, "ORG1")
		require.NoError(t, err)
		assert.Equal(t, "suspended", result.Status)
	})

	t.Run("rejects invalid status", func(t *testing.T) {
		ctx := newMockContext()
		agency := validAgency()
		agencyJSON, _ := json.Marshal(agency)
		_ = contract.CreateAgency(ctx, string(agencyJSON))

		err := contract.UpdateAgencyStatus(ctx, "ORG1", "invalid_status")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid status")
	})

	t.Run("returns error for nonexistent agency", func(t *testing.T) {
		ctx := newMockContext()

		err := contract.UpdateAgencyStatus(ctx, "NONEXISTENT", "suspended")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "not found")
	})
}

func TestGetAllAgencies(t *testing.T) {
	contract := &AgencyContract{}

	t.Run("returns empty list when no agencies", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetAllAgencies(ctx)
		require.NoError(t, err)
		assert.Empty(t, result)
	})

	t.Run("returns all created agencies", func(t *testing.T) {
		ctx := newMockContext()

		// Create multiple agencies
		agency1 := validAgency()
		agency1JSON, _ := json.Marshal(agency1)
		_ = contract.CreateAgency(ctx, string(agency1JSON))

		agency2 := validAgency()
		agency2.AgencyID = "ORG2"
		agency2.Name = "Bay Area Toll Authority"
		agency2JSON, _ := json.Marshal(agency2)
		_ = contract.CreateAgency(ctx, string(agency2JSON))

		result, err := contract.GetAllAgencies(ctx)
		require.NoError(t, err)
		assert.Len(t, result, 2)
	})
}
