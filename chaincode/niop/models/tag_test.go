// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package models

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func validTag() Tag {
	return Tag{
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

func TestTag_Validate(t *testing.T) {
	t.Run("valid tag passes validation", func(t *testing.T) {
		tag := validTag()
		assert.NoError(t, tag.Validate())
	})

	t.Run("valid tag with discount plans and plates", func(t *testing.T) {
		tag := validTag()
		tag.DiscountPlans = []DiscountPlan{
			{Type: "commuter", StartDate: "2026-01-01"},
		}
		tag.Plates = []Plate{
			{Country: "US", State: "CA", Number: "7ABC123"},
		}
		assert.NoError(t, tag.Validate())
	})
}

func TestTag_Validate_RequiredFields(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Tag)
		wantErr string
	}{
		{
			name:    "missing tagSerialNumber",
			modify:  func(tag *Tag) { tag.TagSerialNumber = "" },
			wantErr: "tagSerialNumber is required",
		},
		{
			name:    "missing tagAgencyID",
			modify:  func(tag *Tag) { tag.TagAgencyID = "" },
			wantErr: "tagAgencyID is required",
		},
		{
			name:    "missing homeAgencyID",
			modify:  func(tag *Tag) { tag.HomeAgencyID = "" },
			wantErr: "homeAgencyID is required",
		},
		{
			name:    "missing accountID",
			modify:  func(tag *Tag) { tag.AccountID = "" },
			wantErr: "accountID is required",
		},
		{
			name:    "missing tagStatus",
			modify:  func(tag *Tag) { tag.TagStatus = "" },
			wantErr: "tagStatus is required",
		},
		{
			name:    "missing tagType",
			modify:  func(tag *Tag) { tag.TagType = "" },
			wantErr: "tagType is required",
		},
		{
			name:    "missing tagProtocol",
			modify:  func(tag *Tag) { tag.TagProtocol = "" },
			wantErr: "tagProtocol is required",
		},
		{
			name:    "tagClass zero",
			modify:  func(tag *Tag) { tag.TagClass = 0 },
			wantErr: "tagClass must be >= 1",
		},
		{
			name:    "tagClass negative",
			modify:  func(tag *Tag) { tag.TagClass = -1 },
			wantErr: "tagClass must be >= 1",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tag := validTag()
			tt.modify(&tag)
			err := tag.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestTag_Validate_InvalidEnums(t *testing.T) {
	tests := []struct {
		name    string
		modify  func(*Tag)
		wantErr string
	}{
		{
			name:    "invalid tagStatus",
			modify:  func(tag *Tag) { tag.TagStatus = "destroyed" },
			wantErr: "invalid tagStatus",
		},
		{
			name:    "invalid tagType",
			modify:  func(tag *Tag) { tag.TagType = "rfid" },
			wantErr: "invalid tagType",
		},
		{
			name:    "invalid tagProtocol",
			modify:  func(tag *Tag) { tag.TagProtocol = "bluetooth" },
			wantErr: "invalid tagProtocol",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tag := validTag()
			tt.modify(&tag)
			err := tag.Validate()
			require.Error(t, err)
			assert.Contains(t, err.Error(), tt.wantErr)
		})
	}
}

func TestTag_ValidateStatusTransition(t *testing.T) {
	t.Run("valid transitions from valid", func(t *testing.T) {
		for _, target := range []string{"invalid", "inactive", "lost", "stolen"} {
			t.Run("valid->"+target, func(t *testing.T) {
				tag := validTag()
				assert.NoError(t, tag.ValidateStatusTransition(target))
			})
		}
	})

	t.Run("valid transitions from invalid", func(t *testing.T) {
		tag := validTag()
		tag.TagStatus = "invalid"
		assert.NoError(t, tag.ValidateStatusTransition("valid"))
	})

	t.Run("valid transitions from inactive", func(t *testing.T) {
		for _, target := range []string{"valid", "invalid"} {
			t.Run("inactive->"+target, func(t *testing.T) {
				tag := validTag()
				tag.TagStatus = "inactive"
				assert.NoError(t, tag.ValidateStatusTransition(target))
			})
		}
	})

	t.Run("valid transitions from lost", func(t *testing.T) {
		for _, target := range []string{"valid", "invalid"} {
			t.Run("lost->"+target, func(t *testing.T) {
				tag := validTag()
				tag.TagStatus = "lost"
				assert.NoError(t, tag.ValidateStatusTransition(target))
			})
		}
	})

	t.Run("valid transitions from stolen", func(t *testing.T) {
		for _, target := range []string{"valid", "invalid"} {
			t.Run("stolen->"+target, func(t *testing.T) {
				tag := validTag()
				tag.TagStatus = "stolen"
				assert.NoError(t, tag.ValidateStatusTransition(target))
			})
		}
	})

	t.Run("rejects same status", func(t *testing.T) {
		tag := validTag()
		err := tag.ValidateStatusTransition("valid")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "already in status")
	})

	t.Run("rejects invalid target status", func(t *testing.T) {
		tag := validTag()
		err := tag.ValidateStatusTransition("destroyed")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "invalid target tagStatus")
	})

	t.Run("rejects disallowed transition", func(t *testing.T) {
		tag := validTag()
		tag.TagStatus = "invalid"
		err := tag.ValidateStatusTransition("stolen")
		require.Error(t, err)
		assert.Contains(t, err.Error(), "cannot transition")
	})
}

func TestTag_Key(t *testing.T) {
	tag := Tag{TagSerialNumber: "TEST.000000001"}
	assert.Equal(t, "TAG_TEST.000000001", tag.Key())
}

func TestTag_TouchUpdatedAt(t *testing.T) {
	tag := validTag()
	assert.Empty(t, tag.UpdatedAt)
	assert.Empty(t, tag.DocType)
	tag.TouchUpdatedAt()
	assert.NotEmpty(t, tag.UpdatedAt)
	assert.Equal(t, "tag", tag.DocType)
}

func TestTag_Validate_AllStatuses(t *testing.T) {
	for _, status := range ValidTagStatuses {
		t.Run(status, func(t *testing.T) {
			tag := validTag()
			tag.TagStatus = status
			assert.NoError(t, tag.Validate())
		})
	}
}

func TestTag_Validate_AllTypes(t *testing.T) {
	for _, tagType := range ValidTagTypes {
		t.Run(tagType, func(t *testing.T) {
			tag := validTag()
			tag.TagType = tagType
			assert.NoError(t, tag.Validate())
		})
	}
}

func TestTag_Validate_AllProtocols(t *testing.T) {
	for _, proto := range ValidTagProtocols {
		t.Run(proto, func(t *testing.T) {
			tag := validTag()
			tag.TagProtocol = proto
			assert.NoError(t, tag.Validate())
		})
	}
}
