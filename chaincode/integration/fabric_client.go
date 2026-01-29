// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

//go:build integration

package integration

import (
	"crypto/x509"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/hyperledger/fabric-gateway/pkg/client"
	"github.com/hyperledger/fabric-gateway/pkg/identity"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

// FabricClient wraps a Fabric Gateway connection for a single organization.
type FabricClient struct {
	Gateway    *client.Gateway
	Network    *client.Network
	Contract   *client.Contract
	Org        OrgConfig
	grpcConn   *grpc.ClientConn
	OrgName    string
	Channel    string
	Chaincode  string
}

// NewFabricClient creates a Gateway connection for the specified organization.
func NewFabricClient(orgName string, org OrgConfig, channelName, chaincodeName string) (*FabricClient, error) {
	// Load the admin user certificate
	certPEM, err := os.ReadFile(org.CertPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read certificate from %s: %w", org.CertPath, err)
	}

	cert, err := identity.CertificateFromPEM(certPEM)
	if err != nil {
		return nil, fmt.Errorf("failed to parse certificate: %w", err)
	}

	// Load the admin user private key
	keyPEM, err := loadPrivateKey(org.KeyDir)
	if err != nil {
		return nil, fmt.Errorf("failed to load private key from %s: %w", org.KeyDir, err)
	}

	privateKey, err := identity.PrivateKeyFromPEM(keyPEM)
	if err != nil {
		return nil, fmt.Errorf("failed to parse private key: %w", err)
	}

	// Create identity and sign function
	id, err := identity.NewX509Identity(org.MSPID, cert)
	if err != nil {
		return nil, fmt.Errorf("failed to create identity: %w", err)
	}

	sign, err := identity.NewPrivateKeySign(privateKey)
	if err != nil {
		return nil, fmt.Errorf("failed to create signer: %w", err)
	}

	// Load TLS certificate for peer connection
	tlsCertPEM, err := os.ReadFile(org.TLSCertPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read TLS certificate from %s: %w", org.TLSCertPath, err)
	}

	certPool := x509.NewCertPool()
	if !certPool.AppendCertsFromPEM(tlsCertPEM) {
		return nil, fmt.Errorf("failed to add TLS certificate to pool")
	}

	// Create gRPC connection with TLS
	transportCreds := credentials.NewClientTLSFromCert(certPool, org.GatewayPeerName)
	grpcConn, err := grpc.NewClient(org.PeerEndpoint, grpc.WithTransportCredentials(transportCreds))
	if err != nil {
		return nil, fmt.Errorf("failed to create gRPC connection to %s: %w", org.PeerEndpoint, err)
	}

	// Create Gateway connection
	gw, err := client.Connect(
		id,
		client.WithSign(sign),
		client.WithClientConnection(grpcConn),
		client.WithEvaluateTimeout(5*time.Second),
		client.WithEndorseTimeout(15*time.Second),
		client.WithSubmitTimeout(5*time.Second),
		client.WithCommitStatusTimeout(1*time.Minute),
	)
	if err != nil {
		grpcConn.Close()
		return nil, fmt.Errorf("failed to connect gateway: %w", err)
	}

	network := gw.GetNetwork(channelName)
	contract := network.GetContract(chaincodeName)

	return &FabricClient{
		Gateway:   gw,
		Network:   network,
		Contract:  contract,
		Org:       org,
		grpcConn:  grpcConn,
		OrgName:   orgName,
		Channel:   channelName,
		Chaincode: chaincodeName,
	}, nil
}

// Close releases Gateway and gRPC resources.
func (fc *FabricClient) Close() {
	if fc.Gateway != nil {
		fc.Gateway.Close()
	}
	if fc.grpcConn != nil {
		fc.grpcConn.Close()
	}
}

// contractForFunction maps function names to their contract names.
// Since the chaincode uses multiple contracts, we need to prefix function
// names with the contract name in the format "ContractName:FunctionName".
func contractForFunction(fn string) string {
	// Map of function names to contract names
	functionToContract := map[string]string{
		// AgencyContract
		"CreateAgency":       "AgencyContract",
		"GetAgency":          "AgencyContract",
		"UpdateAgencyStatus": "AgencyContract",
		"GetAllAgencies":     "AgencyContract",
		// TagContract
		"CreateTag":       "TagContract",
		"GetTag":          "TagContract",
		"UpdateTagStatus": "TagContract",
		"GetTagsByAgency": "TagContract",
		// ChargeContract
		"CreateCharge":           "ChargeContract",
		"GetCharge":              "ChargeContract",
		"UpdateChargeStatus":     "ChargeContract",
		"GetChargesByAgencyPair": "ChargeContract",
		// CorrectionContract
		"CreateCorrection":       "CorrectionContract",
		"GetCorrection":          "CorrectionContract",
		"GetCorrectionsForCharge": "CorrectionContract",
		// ReconciliationContract
		"CreateReconciliation":            "ReconciliationContract",
		"GetReconciliation":               "ReconciliationContract",
		"GetReconciliationsByAgency":      "ReconciliationContract",
		"GetReconciliationsByDisposition": "ReconciliationContract",
		// AcknowledgementContract
		"CreateAcknowledgement":              "AcknowledgementContract",
		"GetAcknowledgement":                 "AcknowledgementContract",
		"GetAcknowledgementsBySubmissionType": "AcknowledgementContract",
		"GetAcknowledgementsByReturnCode":    "AcknowledgementContract",
		// SettlementContract
		"CreateSettlement":           "SettlementContract",
		"GetSettlement":              "SettlementContract",
		"UpdateSettlementStatus":     "SettlementContract",
		"GetSettlementsByAgencyPair": "SettlementContract",
		"GetSettlementsByStatus":     "SettlementContract",
	}

	if contract, ok := functionToContract[fn]; ok {
		return contract + ":" + fn
	}
	// Return as-is if not found (may already include contract prefix)
	return fn
}

// SubmitTransaction submits a transaction and waits for commit.
// Use this for operations that modify the ledger (create, update, delete).
func (fc *FabricClient) SubmitTransaction(fn string, args ...string) ([]byte, error) {
	return fc.Contract.SubmitTransaction(contractForFunction(fn), args...)
}

// EvaluateTransaction queries the ledger without submitting a transaction.
// Use this for read-only operations (get, query).
func (fc *FabricClient) EvaluateTransaction(fn string, args ...string) ([]byte, error) {
	return fc.Contract.EvaluateTransaction(contractForFunction(fn), args...)
}

// loadPrivateKey finds and loads the first .pem or _sk file from the keystore directory.
func loadPrivateKey(keyDir string) ([]byte, error) {
	entries, err := os.ReadDir(keyDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read keystore directory: %w", err)
	}

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		// Fabric keystore typically contains files ending in _sk or .pem
		if filepath.Ext(name) == ".pem" || len(name) > 3 && name[len(name)-3:] == "_sk" {
			keyPath := filepath.Join(keyDir, name)
			return os.ReadFile(keyPath)
		}
	}

	return nil, fmt.Errorf("no private key found in %s", keyDir)
}
