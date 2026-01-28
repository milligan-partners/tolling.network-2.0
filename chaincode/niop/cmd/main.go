// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

// NIOP chaincode entry point for Hyperledger Fabric.
// Build with: go build -o niop ./cmd
package main

import (
	"log"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop"
)

func main() {
	chaincode, err := contractapi.NewChaincode(
		&niop.AgencyContract{},
		&niop.TagContract{},
		&niop.ChargeContract{},
		&niop.CorrectionContract{},
		&niop.ReconciliationContract{},
		&niop.AcknowledgementContract{},
		&niop.SettlementContract{},
	)
	if err != nil {
		log.Panicf("Error creating NIOP chaincode: %v", err)
	}

	if err := chaincode.Start(); err != nil {
		log.Panicf("Error starting NIOP chaincode: %v", err)
	}
}
