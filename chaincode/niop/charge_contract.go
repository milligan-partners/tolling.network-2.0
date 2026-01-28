// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
)

// ChargeContract handles Charge transactions on the ledger.
// Charges are stored in bilateral private data collections.
type ChargeContract struct {
	contractapi.Contract
}

// CreateCharge creates a new charge on the ledger.
// The charge is stored in a private data collection named charges_{A}_{B}
// where A and B are alphabetically sorted agency IDs.
func (c *ChargeContract) CreateCharge(ctx contractapi.TransactionContextInterface, chargeJSON string) error {
	var charge models.Charge
	if err := json.Unmarshal([]byte(chargeJSON), &charge); err != nil {
		return fmt.Errorf("failed to parse charge JSON: %w", err)
	}

	if err := charge.Validate(); err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	collection := charge.CollectionName()
	existing, err := ctx.GetStub().GetPrivateData(collection, charge.Key())
	if err != nil {
		return fmt.Errorf("failed to read private data: %w", err)
	}
	if existing != nil {
		return fmt.Errorf("charge %s already exists", charge.ChargeID)
	}

	charge.SetCreatedAt()

	bytes, err := json.Marshal(charge)
	if err != nil {
		return fmt.Errorf("failed to marshal charge: %w", err)
	}

	return ctx.GetStub().PutPrivateData(collection, charge.Key(), bytes)
}

// GetCharge retrieves a charge by ID.
// Requires knowing both agency IDs to determine the collection name.
func (c *ChargeContract) GetCharge(ctx contractapi.TransactionContextInterface, chargeID string, awayAgencyID string, homeAgencyID string) (*models.Charge, error) {
	// Determine collection name using alphabetical sort
	a, b := awayAgencyID, homeAgencyID
	if a > b {
		a, b = b, a
	}
	collection := "charges_" + a + "_" + b
	key := "CHARGE_" + chargeID

	bytes, err := ctx.GetStub().GetPrivateData(collection, key)
	if err != nil {
		return nil, fmt.Errorf("failed to read private data: %w", err)
	}
	if bytes == nil {
		return nil, fmt.Errorf("charge %s not found in collection %s", chargeID, collection)
	}

	var charge models.Charge
	if err := json.Unmarshal(bytes, &charge); err != nil {
		return nil, fmt.Errorf("failed to parse charge: %w", err)
	}

	return &charge, nil
}

// UpdateChargeStatus updates the status of an existing charge.
// Valid transitions: pending->posted/rejected, posted->disputed/settled,
// disputed->posted/settled, rejected->pending.
func (c *ChargeContract) UpdateChargeStatus(ctx contractapi.TransactionContextInterface, chargeID string, awayAgencyID string, homeAgencyID string, newStatus string) error {
	charge, err := c.GetCharge(ctx, chargeID, awayAgencyID, homeAgencyID)
	if err != nil {
		return err
	}

	if err := charge.ValidateStatusTransition(newStatus); err != nil {
		return fmt.Errorf("invalid status transition: %w", err)
	}

	charge.Status = newStatus

	bytes, err := json.Marshal(charge)
	if err != nil {
		return fmt.Errorf("failed to marshal charge: %w", err)
	}

	return ctx.GetStub().PutPrivateData(charge.CollectionName(), charge.Key(), bytes)
}

// GetChargesByAgencyPair returns all charges between two agencies.
// This performs a range scan on the bilateral collection.
func (c *ChargeContract) GetChargesByAgencyPair(ctx contractapi.TransactionContextInterface, agencyA string, agencyB string) ([]*models.Charge, error) {
	// Determine collection name using alphabetical sort
	a, b := agencyA, agencyB
	if a > b {
		a, b = b, a
	}
	collection := "charges_" + a + "_" + b

	resultsIterator, err := ctx.GetStub().GetPrivateDataByRange(collection, "CHARGE_", "CHARGE_~")
	if err != nil {
		return nil, fmt.Errorf("failed to get private data by range: %w", err)
	}
	defer resultsIterator.Close()

	var charges []*models.Charge
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate: %w", err)
		}

		var charge models.Charge
		if err := json.Unmarshal(queryResponse.Value, &charge); err != nil {
			return nil, fmt.Errorf("failed to parse charge: %w", err)
		}
		charges = append(charges, &charge)
	}

	return charges, nil
}
