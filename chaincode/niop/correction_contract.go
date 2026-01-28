// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
)

// CorrectionContract handles Correction transactions on the ledger.
// Corrections are stored in the same bilateral private data collections as charges.
type CorrectionContract struct {
	contractapi.Contract
}

// CreateCorrection creates a new correction for an existing charge.
// The correction is stored in the same private collection as the original charge.
func (c *CorrectionContract) CreateCorrection(ctx contractapi.TransactionContextInterface, correctionJSON string) error {
	var correction models.Correction
	if err := json.Unmarshal([]byte(correctionJSON), &correction); err != nil {
		return fmt.Errorf("failed to parse correction JSON: %w", err)
	}

	if err := correction.Validate(); err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	collection := correction.CollectionName()
	existing, err := ctx.GetStub().GetPrivateData(collection, correction.Key())
	if err != nil {
		return fmt.Errorf("failed to read private data: %w", err)
	}
	if existing != nil {
		return fmt.Errorf("correction %s already exists", correction.Key())
	}

	correction.SetCreatedAt()

	bytes, err := json.Marshal(correction)
	if err != nil {
		return fmt.Errorf("failed to marshal correction: %w", err)
	}

	return ctx.GetStub().PutPrivateData(collection, correction.Key(), bytes)
}

// GetCorrection retrieves a correction by charge ID and sequence number.
func (c *CorrectionContract) GetCorrection(ctx contractapi.TransactionContextInterface, originalChargeID string, seqNo int, fromAgencyID string, toAgencyID string) (*models.Correction, error) {
	// Determine collection name using alphabetical sort
	a, b := fromAgencyID, toAgencyID
	if a > b {
		a, b = b, a
	}
	collection := "charges_" + a + "_" + b
	key := fmt.Sprintf("CORRECTION_%s_%03d", originalChargeID, seqNo)

	bytes, err := ctx.GetStub().GetPrivateData(collection, key)
	if err != nil {
		return nil, fmt.Errorf("failed to read private data: %w", err)
	}
	if bytes == nil {
		return nil, fmt.Errorf("correction %s not found in collection %s", key, collection)
	}

	var correction models.Correction
	if err := json.Unmarshal(bytes, &correction); err != nil {
		return nil, fmt.Errorf("failed to parse correction: %w", err)
	}

	return &correction, nil
}

// GetCorrectionsForCharge returns all corrections for a specific charge.
func (c *CorrectionContract) GetCorrectionsForCharge(ctx contractapi.TransactionContextInterface, originalChargeID string, fromAgencyID string, toAgencyID string) ([]*models.Correction, error) {
	// Determine collection name using alphabetical sort
	a, b := fromAgencyID, toAgencyID
	if a > b {
		a, b = b, a
	}
	collection := "charges_" + a + "_" + b

	startKey := fmt.Sprintf("CORRECTION_%s_", originalChargeID)
	endKey := fmt.Sprintf("CORRECTION_%s_~", originalChargeID)

	resultsIterator, err := ctx.GetStub().GetPrivateDataByRange(collection, startKey, endKey)
	if err != nil {
		return nil, fmt.Errorf("failed to get private data by range: %w", err)
	}
	defer resultsIterator.Close()

	var corrections []*models.Correction
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate: %w", err)
		}

		var correction models.Correction
		if err := json.Unmarshal(queryResponse.Value, &correction); err != nil {
			return nil, fmt.Errorf("failed to parse correction: %w", err)
		}
		corrections = append(corrections, &correction)
	}

	return corrections, nil
}
