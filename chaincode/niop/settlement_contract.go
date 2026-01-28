// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
)

// SettlementContract handles Settlement transactions on the ledger.
// Settlements are stored in bilateral private data collections.
type SettlementContract struct {
	contractapi.Contract
}

// CreateSettlement creates a new settlement on the ledger.
// The settlement is stored in a private data collection named charges_{A}_{B}.
func (c *SettlementContract) CreateSettlement(ctx contractapi.TransactionContextInterface, settlementJSON string) error {
	var settlement models.Settlement
	if err := json.Unmarshal([]byte(settlementJSON), &settlement); err != nil {
		return fmt.Errorf("failed to parse settlement JSON: %w", err)
	}

	if err := settlement.Validate(); err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	collection := settlement.CollectionName()
	existing, err := ctx.GetStub().GetPrivateData(collection, settlement.Key())
	if err != nil {
		return fmt.Errorf("failed to read private data: %w", err)
	}
	if existing != nil {
		return fmt.Errorf("settlement %s already exists", settlement.SettlementID)
	}

	settlement.SetCreatedAt()

	bytes, err := json.Marshal(settlement)
	if err != nil {
		return fmt.Errorf("failed to marshal settlement: %w", err)
	}

	return ctx.GetStub().PutPrivateData(collection, settlement.Key(), bytes)
}

// GetSettlement retrieves a settlement by ID.
// Requires knowing both agency IDs to determine the collection name.
func (c *SettlementContract) GetSettlement(ctx contractapi.TransactionContextInterface, settlementID string, payorAgencyID string, payeeAgencyID string) (*models.Settlement, error) {
	// Determine collection name using alphabetical sort
	a, b := payorAgencyID, payeeAgencyID
	if a > b {
		a, b = b, a
	}
	collection := "charges_" + a + "_" + b
	key := "SETTLEMENT_" + settlementID

	bytes, err := ctx.GetStub().GetPrivateData(collection, key)
	if err != nil {
		return nil, fmt.Errorf("failed to read private data: %w", err)
	}
	if bytes == nil {
		return nil, fmt.Errorf("settlement %s not found in collection %s", settlementID, collection)
	}

	var settlement models.Settlement
	if err := json.Unmarshal(bytes, &settlement); err != nil {
		return nil, fmt.Errorf("failed to parse settlement: %w", err)
	}

	return &settlement, nil
}

// UpdateSettlementStatus updates the status of an existing settlement.
// Valid transitions: draft->submitted, submitted->accepted/disputed,
// accepted->paid, disputed->submitted/accepted.
func (c *SettlementContract) UpdateSettlementStatus(ctx contractapi.TransactionContextInterface, settlementID string, payorAgencyID string, payeeAgencyID string, newStatus string) error {
	settlement, err := c.GetSettlement(ctx, settlementID, payorAgencyID, payeeAgencyID)
	if err != nil {
		return err
	}

	if err := settlement.ValidateStatusTransition(newStatus); err != nil {
		return fmt.Errorf("invalid status transition: %w", err)
	}

	settlement.Status = newStatus

	bytes, err := json.Marshal(settlement)
	if err != nil {
		return fmt.Errorf("failed to marshal settlement: %w", err)
	}

	return ctx.GetStub().PutPrivateData(settlement.CollectionName(), settlement.Key(), bytes)
}

// GetSettlementsByAgencyPair returns all settlements between two agencies.
func (c *SettlementContract) GetSettlementsByAgencyPair(ctx contractapi.TransactionContextInterface, agencyA string, agencyB string) ([]*models.Settlement, error) {
	// Determine collection name using alphabetical sort
	a, b := agencyA, agencyB
	if a > b {
		a, b = b, a
	}
	collection := "charges_" + a + "_" + b

	resultsIterator, err := ctx.GetStub().GetPrivateDataByRange(collection, "SETTLEMENT_", "SETTLEMENT_~")
	if err != nil {
		return nil, fmt.Errorf("failed to get private data by range: %w", err)
	}
	defer resultsIterator.Close()

	var settlements []*models.Settlement
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate: %w", err)
		}

		var settlement models.Settlement
		if err := json.Unmarshal(queryResponse.Value, &settlement); err != nil {
			return nil, fmt.Errorf("failed to parse settlement: %w", err)
		}
		settlements = append(settlements, &settlement)
	}

	return settlements, nil
}

// GetSettlementsByStatus returns all settlements with a specific status for an agency pair.
func (c *SettlementContract) GetSettlementsByStatus(ctx contractapi.TransactionContextInterface, agencyA string, agencyB string, status string) ([]*models.Settlement, error) {
	if !contains(models.ValidSettlementStatuses, status) {
		return nil, fmt.Errorf("invalid status %q: must be one of %v", status, models.ValidSettlementStatuses)
	}

	settlements, err := c.GetSettlementsByAgencyPair(ctx, agencyA, agencyB)
	if err != nil {
		return nil, err
	}

	var filtered []*models.Settlement
	for _, s := range settlements {
		if s.Status == status {
			filtered = append(filtered, s)
		}
	}

	return filtered, nil
}
