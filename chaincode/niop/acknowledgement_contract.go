// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
)

// AcknowledgementContract handles Acknowledgement transactions on the ledger.
// Acknowledgements are stored in world state (public protocol metadata).
type AcknowledgementContract struct {
	contractapi.Contract
}

// CreateAcknowledgement creates a new acknowledgement on the ledger.
// Returns an error if the acknowledgement already exists or validation fails.
func (c *AcknowledgementContract) CreateAcknowledgement(ctx contractapi.TransactionContextInterface, ackJSON string) error {
	var ack models.Acknowledgement
	if err := json.Unmarshal([]byte(ackJSON), &ack); err != nil {
		return fmt.Errorf("failed to parse acknowledgement JSON: %w", err)
	}

	if err := ack.Validate(); err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	existing, err := ctx.GetStub().GetState(ack.Key())
	if err != nil {
		return fmt.Errorf("failed to read state: %w", err)
	}
	if existing != nil {
		return fmt.Errorf("acknowledgement %s already exists", ack.AcknowledgementID)
	}

	ack.SetCreatedAt()

	bytes, err := json.Marshal(ack)
	if err != nil {
		return fmt.Errorf("failed to marshal acknowledgement: %w", err)
	}

	return ctx.GetStub().PutState(ack.Key(), bytes)
}

// GetAcknowledgement retrieves an acknowledgement by ID.
func (c *AcknowledgementContract) GetAcknowledgement(ctx contractapi.TransactionContextInterface, acknowledgementID string) (*models.Acknowledgement, error) {
	key := "ACK_" + acknowledgementID
	bytes, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to read state: %w", err)
	}
	if bytes == nil {
		return nil, fmt.Errorf("acknowledgement %s not found", acknowledgementID)
	}

	var ack models.Acknowledgement
	if err := json.Unmarshal(bytes, &ack); err != nil {
		return nil, fmt.Errorf("failed to parse acknowledgement: %w", err)
	}

	return &ack, nil
}

// GetAcknowledgementsBySubmissionType returns all acknowledgements of a specific type.
func (c *AcknowledgementContract) GetAcknowledgementsBySubmissionType(ctx contractapi.TransactionContextInterface, submissionType string) ([]*models.Acknowledgement, error) {
	if !contains(models.ValidSubmissionTypes, submissionType) {
		return nil, fmt.Errorf("invalid submissionType %q: must be one of %v", submissionType, models.ValidSubmissionTypes)
	}

	resultsIterator, err := ctx.GetStub().GetStateByRange("ACK_", "ACK_~")
	if err != nil {
		return nil, fmt.Errorf("failed to get state by range: %w", err)
	}
	defer resultsIterator.Close()

	var acks []*models.Acknowledgement
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate: %w", err)
		}

		var ack models.Acknowledgement
		if err := json.Unmarshal(queryResponse.Value, &ack); err != nil {
			return nil, fmt.Errorf("failed to parse acknowledgement: %w", err)
		}
		if ack.SubmissionType == submissionType {
			acks = append(acks, &ack)
		}
	}

	return acks, nil
}

// GetAcknowledgementsByReturnCode returns all acknowledgements with a specific return code.
func (c *AcknowledgementContract) GetAcknowledgementsByReturnCode(ctx contractapi.TransactionContextInterface, returnCode string) ([]*models.Acknowledgement, error) {
	if !contains(models.ValidReturnCodes, returnCode) {
		return nil, fmt.Errorf("invalid returnCode %q: must be one of 00-13", returnCode)
	}

	resultsIterator, err := ctx.GetStub().GetStateByRange("ACK_", "ACK_~")
	if err != nil {
		return nil, fmt.Errorf("failed to get state by range: %w", err)
	}
	defer resultsIterator.Close()

	var acks []*models.Acknowledgement
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate: %w", err)
		}

		var ack models.Acknowledgement
		if err := json.Unmarshal(queryResponse.Value, &ack); err != nil {
			return nil, fmt.Errorf("failed to parse acknowledgement: %w", err)
		}
		if ack.ReturnCode == returnCode {
			acks = append(acks, &ack)
		}
	}

	return acks, nil
}
