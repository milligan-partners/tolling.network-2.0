// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"testing"

	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func validTag() *models.Tag {
	return &models.Tag{
		TagSerialNumber: "TEST.000000001",
		TagAgencyID:     "ORG1",
		HomeAgencyID:    "ORG1",
		AccountID:       "A000000001",
		TagStatus:       "valid",
		TagType:         "single",
		TagClass:        2,
		TagProtocol:     "6c",
	}
}

func TestCreateTag(t *testing.T) {
	contract := &TagContract{}

	t.Run("creates valid tag", func(t *testing.T) {
		ctx := newMockContext()
		tag := validTag()
		tagJSON, _ := json.Marshal(tag)

		err := contract.CreateTag(ctx, string(tagJSON))
		require.NoError(t, err)

		// Verify state was written
		bytes, err := ctx.stub.GetState("TAG_TEST.000000001")
		require.NoError(t, err)
		require.NotNil(t, bytes)

		var stored models.Tag
		err = json.Unmarshal(bytes, &stored)
		require.NoError(t, err)
		assert.Equal(t, "TEST.000000001", stored.TagSerialNumber)
		assert.Equal(t, "ORG1", stored.TagAgencyID)
		assert.NotEmpty(t, stored.UpdatedAt)
	})

	t.Run("rejects duplicate tag", func(t *testing.T) {
		ctx := newMockContext()
		tag := validTag()
		tagJSON, _ := json.Marshal(tag)

		err := contract.CreateTag(ctx, string(tagJSON))
		require.NoError(t, err)

		err = contract.CreateTag(ctx, string(tagJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "already exists")
	})

	t.Run("rejects invalid JSON", func(t *testing.T) {
		ctx := newMockContext()
		err := contract.CreateTag(ctx, "not valid json")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "failed to parse")
	})

	t.Run("rejects missing required fields", func(t *testing.T) {
		ctx := newMockContext()
		tag := &models.Tag{
			TagSerialNumber: "", // missing
			TagAgencyID:     "ORG1",
		}
		tagJSON, _ := json.Marshal(tag)

		err := contract.CreateTag(ctx, string(tagJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "validation failed")
	})

	t.Run("rejects invalid status", func(t *testing.T) {
		ctx := newMockContext()
		tag := validTag()
		tag.TagStatus = "invalid_status"
		tagJSON, _ := json.Marshal(tag)

		err := contract.CreateTag(ctx, string(tagJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid tagStatus")
	})
}

func TestGetTag(t *testing.T) {
	contract := &TagContract{}

	t.Run("retrieves existing tag", func(t *testing.T) {
		ctx := newMockContext()
		tag := validTag()
		tagJSON, _ := json.Marshal(tag)
		_ = contract.CreateTag(ctx, string(tagJSON))

		result, err := contract.GetTag(ctx, "TEST.000000001")
		require.NoError(t, err)
		require.NotNil(t, result)
		assert.Equal(t, "TEST.000000001", result.TagSerialNumber)
		assert.Equal(t, "ORG1", result.TagAgencyID)
	})

	t.Run("returns error for nonexistent tag", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetTag(ctx, "NONEXISTENT")
		require.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "not found")
	})
}

func TestUpdateTagStatus(t *testing.T) {
	contract := &TagContract{}

	t.Run("updates status with valid transition", func(t *testing.T) {
		ctx := newMockContext()
		tag := validTag()
		tagJSON, _ := json.Marshal(tag)
		_ = contract.CreateTag(ctx, string(tagJSON))

		// valid -> invalid is allowed
		err := contract.UpdateTagStatus(ctx, "TEST.000000001", "invalid")
		require.NoError(t, err)

		result, err := contract.GetTag(ctx, "TEST.000000001")
		require.NoError(t, err)
		assert.Equal(t, "invalid", result.TagStatus)
	})

	t.Run("updates status to lost", func(t *testing.T) {
		ctx := newMockContext()
		tag := validTag()
		tagJSON, _ := json.Marshal(tag)
		_ = contract.CreateTag(ctx, string(tagJSON))

		// valid -> lost is allowed
		err := contract.UpdateTagStatus(ctx, "TEST.000000001", "lost")
		require.NoError(t, err)

		result, err := contract.GetTag(ctx, "TEST.000000001")
		require.NoError(t, err)
		assert.Equal(t, "lost", result.TagStatus)
	})

	t.Run("rejects invalid status transition", func(t *testing.T) {
		ctx := newMockContext()
		tag := validTag()
		tag.TagStatus = "invalid" // start as invalid
		tagJSON, _ := json.Marshal(tag)
		_ = contract.CreateTag(ctx, string(tagJSON))

		// invalid -> lost is NOT allowed (only invalid -> valid)
		err := contract.UpdateTagStatus(ctx, "TEST.000000001", "lost")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "cannot transition")
	})

	t.Run("rejects invalid status value", func(t *testing.T) {
		ctx := newMockContext()
		tag := validTag()
		tagJSON, _ := json.Marshal(tag)
		_ = contract.CreateTag(ctx, string(tagJSON))

		err := contract.UpdateTagStatus(ctx, "TEST.000000001", "bad_status")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid target tagStatus")
	})

	t.Run("returns error for nonexistent tag", func(t *testing.T) {
		ctx := newMockContext()

		err := contract.UpdateTagStatus(ctx, "NONEXISTENT", "invalid")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "not found")
	})
}

func TestGetTagsByAgency(t *testing.T) {
	contract := &TagContract{}

	t.Run("returns empty list when no tags", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetTagsByAgency(ctx, "ORG1")
		require.NoError(t, err)
		assert.Empty(t, result)
	})

	t.Run("returns tags for specific agency", func(t *testing.T) {
		ctx := newMockContext()

		// Create tags for ORG1
		tag1 := validTag()
		tag1JSON, _ := json.Marshal(tag1)
		_ = contract.CreateTag(ctx, string(tag1JSON))

		tag2 := validTag()
		tag2.TagSerialNumber = "TEST.000000002"
		tag2JSON, _ := json.Marshal(tag2)
		_ = contract.CreateTag(ctx, string(tag2JSON))

		// Create tag for different agency
		tag3 := validTag()
		tag3.TagSerialNumber = "TEST.000000003"
		tag3.TagAgencyID = "ORG2"
		tag3JSON, _ := json.Marshal(tag3)
		_ = contract.CreateTag(ctx, string(tag3JSON))

		// Should only return ORG1 tags
		result, err := contract.GetTagsByAgency(ctx, "ORG1")
		require.NoError(t, err)
		assert.Len(t, result, 2)
	})
}
