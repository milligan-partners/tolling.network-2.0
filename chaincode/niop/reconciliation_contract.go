// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop/models"
)

// ReconciliationContract handles Reconciliation transactions on the ledger.
// Reconciliations are stored in world state keyed by the charge ID they reference.
type ReconciliationContract struct {
	contractapi.Contract
}

// CreateReconciliation creates a new reconciliation record for a charge.
// Returns an error if a reconciliation for this charge already exists.
func (c *ReconciliationContract) CreateReconciliation(ctx contractapi.TransactionContextInterface, reconciliationJSON string) error {
	var recon models.Reconciliation
	if err := json.Unmarshal([]byte(reconciliationJSON), &recon); err != nil {
		return fmt.Errorf("failed to parse reconciliation JSON: %w", err)
	}

	if err := recon.Validate(); err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	existing, err := ctx.GetStub().GetState(recon.Key())
	if err != nil {
		return fmt.Errorf("failed to read state: %w", err)
	}
	if existing != nil {
		return fmt.Errorf("reconciliation for charge %s already exists", recon.ChargeID)
	}

	recon.SetCreatedAt()

	bytes, err := json.Marshal(recon)
	if err != nil {
		return fmt.Errorf("failed to marshal reconciliation: %w", err)
	}

	return ctx.GetStub().PutState(recon.Key(), bytes)
}

// GetReconciliation retrieves a reconciliation by charge ID.
func (c *ReconciliationContract) GetReconciliation(ctx contractapi.TransactionContextInterface, chargeID string) (*models.Reconciliation, error) {
	key := "RECON_" + chargeID
	bytes, err := ctx.GetStub().GetState(key)
	if err != nil {
		return nil, fmt.Errorf("failed to read state: %w", err)
	}
	if bytes == nil {
		return nil, fmt.Errorf("reconciliation for charge %s not found", chargeID)
	}

	var recon models.Reconciliation
	if err := json.Unmarshal(bytes, &recon); err != nil {
		return nil, fmt.Errorf("failed to parse reconciliation: %w", err)
	}

	return &recon, nil
}

// GetReconciliationsByAgency returns all reconciliations for a home agency.
// This performs a range scan and filters by agency.
func (c *ReconciliationContract) GetReconciliationsByAgency(ctx contractapi.TransactionContextInterface, homeAgencyID string) ([]*models.Reconciliation, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("RECON_", "RECON_~")
	if err != nil {
		return nil, fmt.Errorf("failed to get state by range: %w", err)
	}
	defer resultsIterator.Close()

	var reconciliations []*models.Reconciliation
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate: %w", err)
		}

		var recon models.Reconciliation
		if err := json.Unmarshal(queryResponse.Value, &recon); err != nil {
			return nil, fmt.Errorf("failed to parse reconciliation: %w", err)
		}
		if recon.HomeAgencyID == homeAgencyID {
			reconciliations = append(reconciliations, &recon)
		}
	}

	return reconciliations, nil
}

// GetReconciliationsByDisposition returns all reconciliations with a specific disposition.
func (c *ReconciliationContract) GetReconciliationsByDisposition(ctx contractapi.TransactionContextInterface, disposition string) ([]*models.Reconciliation, error) {
	if !contains(models.ValidPostingDispositions, disposition) {
		return nil, fmt.Errorf("invalid postingDisposition %q: must be one of %v", disposition, models.ValidPostingDispositions)
	}

	resultsIterator, err := ctx.GetStub().GetStateByRange("RECON_", "RECON_~")
	if err != nil {
		return nil, fmt.Errorf("failed to get state by range: %w", err)
	}
	defer resultsIterator.Close()

	var reconciliations []*models.Reconciliation
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to iterate: %w", err)
		}

		var recon models.Reconciliation
		if err := json.Unmarshal(queryResponse.Value, &recon); err != nil {
			return nil, fmt.Errorf("failed to parse reconciliation: %w", err)
		}
		if recon.PostingDisposition == disposition {
			reconciliations = append(reconciliations, &recon)
		}
	}

	return reconciliations, nil
}
