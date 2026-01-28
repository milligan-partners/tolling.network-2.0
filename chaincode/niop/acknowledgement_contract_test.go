// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"testing"

	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func validAcknowledgement() *models.Acknowledgement {
	return &models.Acknowledgement{
		AcknowledgementID: "ACK-TEST-001",
		SubmissionType:    "STVL",
		FromAgencyID:      "ORG1",
		ToAgencyID:        "ORG2",
		ReturnCode:        "00",
		ReturnMessage:     "Success",
	}
}

func TestCreateAcknowledgement(t *testing.T) {
	contract := &AcknowledgementContract{}

	t.Run("creates valid acknowledgement", func(t *testing.T) {
		ctx := newMockContext()
		ack := validAcknowledgement()
		ackJSON, _ := json.Marshal(ack)

		err := contract.CreateAcknowledgement(ctx, string(ackJSON))
		require.NoError(t, err)

		bytes, err := ctx.stub.GetState("ACK_ACK-TEST-001")
		require.NoError(t, err)
		require.NotNil(t, bytes)

		var stored models.Acknowledgement
		err = json.Unmarshal(bytes, &stored)
		require.NoError(t, err)
		assert.Equal(t, "ACK-TEST-001", stored.AcknowledgementID)
		assert.Equal(t, "00", stored.ReturnCode)
		assert.NotEmpty(t, stored.CreatedAt)
	})

	t.Run("rejects duplicate acknowledgement", func(t *testing.T) {
		ctx := newMockContext()
		ack := validAcknowledgement()
		ackJSON, _ := json.Marshal(ack)

		err := contract.CreateAcknowledgement(ctx, string(ackJSON))
		require.NoError(t, err)

		err = contract.CreateAcknowledgement(ctx, string(ackJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "already exists")
	})

	t.Run("rejects invalid submission type", func(t *testing.T) {
		ctx := newMockContext()
		ack := validAcknowledgement()
		ack.SubmissionType = "INVALID"
		ackJSON, _ := json.Marshal(ack)

		err := contract.CreateAcknowledgement(ctx, string(ackJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid submissionType")
	})

	t.Run("rejects invalid return code", func(t *testing.T) {
		ctx := newMockContext()
		ack := validAcknowledgement()
		ack.ReturnCode = "99" // invalid
		ackJSON, _ := json.Marshal(ack)

		err := contract.CreateAcknowledgement(ctx, string(ackJSON))
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid returnCode")
	})
}

func TestGetAcknowledgement(t *testing.T) {
	contract := &AcknowledgementContract{}

	t.Run("retrieves existing acknowledgement", func(t *testing.T) {
		ctx := newMockContext()
		ack := validAcknowledgement()
		ackJSON, _ := json.Marshal(ack)
		_ = contract.CreateAcknowledgement(ctx, string(ackJSON))

		result, err := contract.GetAcknowledgement(ctx, "ACK-TEST-001")
		require.NoError(t, err)
		require.NotNil(t, result)
		assert.Equal(t, "ACK-TEST-001", result.AcknowledgementID)
		assert.Equal(t, "STVL", result.SubmissionType)
	})

	t.Run("returns error for nonexistent acknowledgement", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetAcknowledgement(ctx, "ACK-NONEXISTENT")
		require.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "not found")
	})
}

func TestGetAcknowledgementsBySubmissionType(t *testing.T) {
	contract := &AcknowledgementContract{}

	t.Run("rejects invalid submission type", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetAcknowledgementsBySubmissionType(ctx, "INVALID")
		require.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "invalid submissionType")
	})

	t.Run("returns acknowledgements by type", func(t *testing.T) {
		ctx := newMockContext()

		ack1 := validAcknowledgement()
		ack1JSON, _ := json.Marshal(ack1)
		_ = contract.CreateAcknowledgement(ctx, string(ack1JSON))

		ack2 := validAcknowledgement()
		ack2.AcknowledgementID = "ACK-TEST-002"
		ack2.SubmissionType = "STRAN" // different type
		ack2JSON, _ := json.Marshal(ack2)
		_ = contract.CreateAcknowledgement(ctx, string(ack2JSON))

		result, err := contract.GetAcknowledgementsBySubmissionType(ctx, "STVL")
		require.NoError(t, err)
		assert.Len(t, result, 1)
		assert.Equal(t, "STVL", result[0].SubmissionType)
	})
}

func TestGetAcknowledgementsByReturnCode(t *testing.T) {
	contract := &AcknowledgementContract{}

	t.Run("rejects invalid return code", func(t *testing.T) {
		ctx := newMockContext()

		result, err := contract.GetAcknowledgementsByReturnCode(ctx, "99")
		require.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), "invalid returnCode")
	})

	t.Run("returns acknowledgements by return code", func(t *testing.T) {
		ctx := newMockContext()

		ack1 := validAcknowledgement()
		ack1JSON, _ := json.Marshal(ack1)
		_ = contract.CreateAcknowledgement(ctx, string(ack1JSON))

		ack2 := validAcknowledgement()
		ack2.AcknowledgementID = "ACK-TEST-002"
		ack2.ReturnCode = "06" // format error
		ack2JSON, _ := json.Marshal(ack2)
		_ = contract.CreateAcknowledgement(ctx, string(ack2JSON))

		result, err := contract.GetAcknowledgementsByReturnCode(ctx, "00")
		require.NoError(t, err)
		assert.Len(t, result, 1)
		assert.Equal(t, "00", result[0].ReturnCode)
	})
}
