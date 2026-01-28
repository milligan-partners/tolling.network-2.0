// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
)

// TagContract handles Tag transactions on the ledger.
// Tags are stored in world state for now (TVL private collections are a future enhancement).
type TagContract struct {
	contractapi.Contract
}

// CreateTag creates a new tag on the ledger.
// Returns an error if the tag already exists or validation fails.
func (c *TagContract) CreateTag(ctx contractapi.TransactionContextInterface, tagJSON string) error {
	var tag models.Tag
	if err := json.Unmarshal([]byte(tagJSON), &tag); err != nil {
		return fmt.Errorf("failed to parse tag JSON: %w", err)
	}

	if err := tag.Validate(); err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	existing, err := ctx.GetStub().GetState(tag.Key())
	if err != nil {
		return fmt.Errorf("failed to read state: %w", err)
	}
	if existing != nil {
		return fmt.Errorf("tag %s already exists", tag.TagSerialNumber)
	}

	tag.TouchUpdatedAt()

	bytes, err := json.Marshal(tag)
	if err != nil {
		return fmt.Errorf("failed to marshal tag: %w", err)
	}

	return ctx.GetStub().PutState(tag.Key(), bytes)
}

// GetTag retrieves a tag by serial number.
// Returns nil and an error if the tag does not exist.
func (c *TagContract) GetTag(ctx contractapi.TransactionContextInterface, tagSerialNumber string) (*models.Tag, error) {
	key := "TAG_" + tagSerialNumber
	bytes, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to read state: %w", err)
	}
	if bytes == nil {
		return nil, fmt.Errorf("tag %s not found", tagSerialNumber)
	}

	var tag models.Tag
	if err := json.Unmarshal(bytes, &tag); err != nil {
		return nil, fmt.Errorf("failed to parse tag: %w", err)
	}

	return &tag, nil
}

// UpdateTagStatus updates the status of an existing tag.
// Valid status values: valid, invalid, inactive, lost, stolen.
// Validates that the transition is allowed per the status lifecycle.
func (c *TagContract) UpdateTagStatus(ctx contractapi.TransactionContextInterface, tagSerialNumber string, newStatus string) error {
	tag, err := c.GetTag(ctx, tagSerialNumber)
	if err != nil {
		return err
	}

	if err := tag.ValidateStatusTransition(newStatus); err != nil {
		return fmt.Errorf("invalid status transition: %w", err)
	}

	tag.TagStatus = newStatus
	tag.TouchUpdatedAt()

	bytes, err := json.Marshal(tag)
	if err != nil {
		return fmt.Errorf("failed to marshal tag: %w", err)
	}

	return ctx.GetStub().PutState(tag.Key(), bytes)
}

// GetTagsByAgency returns all tags issued by a specific agency.
// This uses a range query which may be slow for large datasets.
// Consider CouchDB indexes for production use.
func (c *TagContract) GetTagsByAgency(ctx contractapi.TransactionContextInterface, tagAgencyID string) ([]*models.Tag, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("TAG_", "TAG_~")
	if err != nil {
		return nil, fmt.Errorf("failed to get state by range: %w", err)
	}
	defer resultsIterator.Close()

	var tags []*models.Tag
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate: %w", err)
		}

		var tag models.Tag
		if err := json.Unmarshal(queryResponse.Value, &tag); err != nil {
			return nil, fmt.Errorf("failed to parse tag: %w", err)
		}
		if tag.TagAgencyID == tagAgencyID {
			tags = append(tags, &tag)
		}
	}

	return tags, nil
}
