// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
)

// AgencyContract handles Agency transactions on the ledger.
// Agencies are stored in world state (public to channel members).
type AgencyContract struct {
	contractapi.Contract
}

// CreateAgency creates a new agency on the ledger.
// Returns an error if the agency already exists or validation fails.
func (c *AgencyContract) CreateAgency(ctx contractapi.TransactionContextInterface, agencyJSON string) error {
	var agency models.Agency
	if err := json.Unmarshal([]byte(agencyJSON), &agency); err != nil {
		return fmt.Errorf("failed to parse agency JSON: %w", err)
	}

	if err := agency.Validate(); err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	existing, err := ctx.GetStub().GetState(agency.Key())
	if err != nil {
		return fmt.Errorf("failed to read state: %w", err)
	}
	if existing != nil {
		return fmt.Errorf("agency %s already exists", agency.AgencyID)
	}

	agency.SetTimestamps()

	bytes, err := json.Marshal(agency)
	if err != nil {
		return fmt.Errorf("failed to marshal agency: %w", err)
	}

	return ctx.GetStub().PutState(agency.Key(), bytes)
}

// GetAgency retrieves an agency by ID.
// Returns nil and an error if the agency does not exist.
func (c *AgencyContract) GetAgency(ctx contractapi.TransactionContextInterface, agencyID string) (*models.Agency, error) {
	key := "AGENCY_" + agencyID
	bytes, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to read state: %w", err)
	}
	if bytes == nil {
		return nil, fmt.Errorf("agency %s not found", agencyID)
	}

	var agency models.Agency
	if err := json.Unmarshal(bytes, &agency); err != nil {
		return nil, fmt.Errorf("failed to parse agency: %w", err)
	}

	return &agency, nil
}

// UpdateAgencyStatus updates the status of an existing agency.
// Valid status values: active, suspended, onboarding.
func (c *AgencyContract) UpdateAgencyStatus(ctx contractapi.TransactionContextInterface, agencyID string, newStatus string) error {
	agency, err := c.GetAgency(ctx, agencyID)
	if err != nil {
		return err
	}

	if !contains(models.ValidAgencyStatuses, newStatus) {
		return fmt.Errorf("invalid status %q: must be one of %v", newStatus, models.ValidAgencyStatuses)
	}

	agency.Status = newStatus
	agency.TouchUpdatedAt()

	bytes, err := json.Marshal(agency)
	if err != nil {
		return fmt.Errorf("failed to marshal agency: %w", err)
	}

	return ctx.GetStub().PutState(agency.Key(), bytes)
}

// GetAllAgencies returns all agencies on the ledger.
// This uses a range query on the AGENCY_ prefix.
func (c *AgencyContract) GetAllAgencies(ctx contractapi.TransactionContextInterface) ([]*models.Agency, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("AGENCY_", "AGENCY_~")
	if err != nil {
		return nil, fmt.Errorf("failed to get state by range: %w", err)
	}
	defer resultsIterator.Close()

	var agencies []*models.Agency
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate: %w", err)
		}

		var agency models.Agency
		if err := json.Unmarshal(queryResponse.Value, &agency); err != nil {
			return nil, fmt.Errorf("failed to parse agency: %w", err)
		}
		agencies = append(agencies, &agency)
	}

	return agencies, nil
}

// contains checks if a string is in a slice.
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
