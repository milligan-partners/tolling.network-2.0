// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func validAcknowledgement() Acknowledgement {
	return Acknowledgement{
		AcknowledgementID: "ACK-TEST-001",
		SubmissionType:    "STVL",
		FromAgencyID:      "ORG1",
		ToAgencyID:        "ORG2",
		ReturnCode:        "00",
		ReturnMessage:     "Success",
	}
}

func TestAcknowledgement_Validate(t *testing.T) {
	t.Run("valid success acknowledgement", func(t *testing.T) {
		a := validAcknowledgement()
		assert.NoError(t, a.Validate())
	})

	t.Run("valid error acknowledgement", func(t *testing.T) {
		a := validAcknowledgement()
		a.ReturnCode = "06"
		a.ReturnMessage = "Format error"
		assert.NoError(t, a.Validate())
	})

	t.Run("valid acknowledgement without return message", func(t *testing.T) {
		a := validAcknowledgement()
		a.ReturnMessage = ""
		assert.NoError(t, a.Validate())
	})
}

func TestAcknowledgement_Validate_RequiredFields(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Acknowledgement)
		wantErr string
	}{
		{
			name:    "missing acknowledgementID",
			modify:  func(a *Acknowledgement) { a.AcknowledgementID = "" },
			wantErr: "acknowledgementID is required",
		},
		{
			name:    "missing submissionType",
			modify:  func(a *Acknowledgement) { a.SubmissionType = "" },
			wantErr: "submissionType is required",
		},
		{
			name:    "missing fromAgencyID",
			modify:  func(a *Acknowledgement) { a.FromAgencyID = "" },
			wantErr: "fromAgencyID is required",
		},
		{
			name:    "missing toAgencyID",
			modify:  func(a *Acknowledgement) { a.ToAgencyID = "" },
			wantErr: "toAgencyID is required",
		},
		{
			name:    "missing returnCode",
			modify:  func(a *Acknowledgement) { a.ReturnCode = "" },
			wantErr: "returnCode is required",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			a := validAcknowledgement()
			tt.modify(&a)
			err := a.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestAcknowledgement_Validate_InvalidEnums(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Acknowledgement)
		wantErr string
	}{
		{
			name:    "invalid submissionType",
			modify:  func(a *Acknowledgement) { a.SubmissionType = "SDATA" },
			wantErr: "invalid submissionType",
		},
		{
			name:    "invalid returnCode too high",
			modify:  func(a *Acknowledgement) { a.ReturnCode = "14" },
			wantErr: "invalid returnCode",
		},
		{
			name:    "invalid returnCode non-numeric",
			modify:  func(a *Acknowledgement) { a.ReturnCode = "XX" },
			wantErr: "invalid returnCode",
		},
		{
			name:    "invalid returnCode single digit",
			modify:  func(a *Acknowledgement) { a.ReturnCode = "0" },
			wantErr: "invalid returnCode",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			a := validAcknowledgement()
			tt.modify(&a)
			err := a.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestAcknowledgement_Key(t *testing.T) {
	a := Acknowledgement{AcknowledgementID: "ACK-001"}
	assert.Equal(t, "ACK_ACK-001", a.Key())
}

func TestAcknowledgement_SetCreatedAt(t *testing.T) {
	a := validAcknowledgement()
	assert.Empty(t, a.CreatedAt)
	assert.Empty(t, a.DocType)
	a.SetCreatedAt()
	assert.NotEmpty(t, a.CreatedAt)
	assert.Equal(t, "acknowledgement", a.DocType)
}

func TestAcknowledgement_IsSuccess(t *testing.T) {
	t.Run("return code 00 is success", func(t *testing.T) {
		a := validAcknowledgement()
		a.ReturnCode = "00"
		assert.True(t, a.IsSuccess())
	})

	t.Run("non-00 codes are not success", func(t *testing.T) {
		for _, code := range []string{"01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13"} {
			t.Run("code_"+code, func(t *testing.T) {
				a := validAcknowledgement()
				a.ReturnCode = code
				assert.False(t, a.IsSuccess())
			})
		}
	})
}

func TestAcknowledgement_Validate_AllSubmissionTypes(t *testing.T) {
	for _, st := range ValidSubmissionTypes {
		t.Run(st, func(t *testing.T) {
			a := validAcknowledgement()
			a.SubmissionType = st
			assert.NoError(t, a.Validate())
		})
	}
}

func TestAcknowledgement_Validate_AllReturnCodes(t *testing.T) {
	for _, rc := range ValidReturnCodes {
		t.Run("code_"+rc, func(t *testing.T) {
			a := validAcknowledgement()
			a.ReturnCode = rc
			assert.NoError(t, a.Validate())
		})
	}
}
