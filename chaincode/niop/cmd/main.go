// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

// NIOP chaincode entry point for Hyperledger Fabric.
//
// This chaincode supports two modes:
//
//  1. Traditional mode (peer-managed): The peer starts and manages the chaincode.
//     This is the default mode when no environment variables are set.
//
//  2. Chaincode as a Service (ccaas) mode: The chaincode runs as an external
//     gRPC server that the peer connects to. This mode is activated when
//     CHAINCODE_SERVER_ADDRESS is set.
//
// Environment variables for ccaas mode:
//   - CHAINCODE_ID: The package ID assigned during chaincode installation (required)
//   - CHAINCODE_SERVER_ADDRESS: Address to listen on, e.g., "0.0.0.0:9999" (required)
//   - CHAINCODE_TLS_DISABLED: Set to "true" to disable TLS (default: false)
//   - CHAINCODE_TLS_KEY: Path to TLS private key file
//   - CHAINCODE_TLS_CERT: Path to TLS certificate file
//   - CHAINCODE_TLS_CLIENT_CA_CERT: Path to client CA certificate for mutual TLS
//
// Build with: go build -o niop ./cmd
package main

import (
	"crypto/tls"
	"crypto/x509"
	"log"
	"os"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/milligan-partners/tolling.network-2.0/chaincode/niop"
)

func main() {
	// Create chaincode with all contracts
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

	// Check if running in ccaas mode
	ccServerAddress := os.Getenv("CHAINCODE_SERVER_ADDRESS")
	if ccServerAddress != "" {
		// Chaincode as a Service mode
		startChaincodeServer(chaincode, ccServerAddress)
	} else {
		// Traditional peer-managed mode
		if err := chaincode.Start(); err != nil {
			log.Panicf("Error starting NIOP chaincode: %v", err)
		}
	}
}

// startChaincodeServer starts the chaincode as an external gRPC server
// that peers connect to.
func startChaincodeServer(cc *contractapi.ContractChaincode, address string) {
	ccID := os.Getenv("CHAINCODE_ID")
	if ccID == "" {
		log.Panicf("CHAINCODE_ID environment variable is required in ccaas mode")
	}

	log.Printf("Starting NIOP chaincode server in ccaas mode")
	log.Printf("  Chaincode ID: %s", ccID)
	log.Printf("  Server address: %s", address)

	// Configure TLS
	var tlsConfig *tls.Config
	tlsDisabled := os.Getenv("CHAINCODE_TLS_DISABLED")
	if tlsDisabled != "true" {
		tlsConfig = getTLSConfig()
		if tlsConfig != nil {
			log.Printf("  TLS: enabled")
		} else {
			log.Printf("  TLS: disabled (no certificates configured)")
		}
	} else {
		log.Printf("  TLS: explicitly disabled")
	}

	// Create chaincode server configuration
	server := &shim.ChaincodeServer{
		CCID:      ccID,
		Address:   address,
		CC:        cc,
		TLSProps:  getTLSProperties(tlsConfig),
	}

	// Start the chaincode server
	log.Printf("Chaincode server starting...")
	if err := server.Start(); err != nil {
		log.Panicf("Error starting chaincode server: %v", err)
	}
}

// getTLSConfig builds TLS configuration from environment variables
func getTLSConfig() *tls.Config {
	keyPath := os.Getenv("CHAINCODE_TLS_KEY")
	certPath := os.Getenv("CHAINCODE_TLS_CERT")

	if keyPath == "" || certPath == "" {
		return nil
	}

	// Load server certificate and key
	cert, err := tls.LoadX509KeyPair(certPath, keyPath)
	if err != nil {
		log.Printf("Warning: Failed to load TLS certificate: %v", err)
		return nil
	}

	config := &tls.Config{
		Certificates: []tls.Certificate{cert},
		MinVersion:   tls.VersionTLS12,
	}

	// Load client CA certificate for mutual TLS if provided
	clientCACertPath := os.Getenv("CHAINCODE_TLS_CLIENT_CA_CERT")
	if clientCACertPath != "" {
		clientCACert, err := os.ReadFile(clientCACertPath)
		if err != nil {
			log.Printf("Warning: Failed to load client CA certificate: %v", err)
		} else {
			clientCAPool := x509.NewCertPool()
			if clientCAPool.AppendCertsFromPEM(clientCACert) {
				config.ClientCAs = clientCAPool
				config.ClientAuth = tls.RequireAndVerifyClientCert
			}
		}
	}

	return config
}

// getTLSProperties converts tls.Config to shim.TLSProperties
func getTLSProperties(config *tls.Config) shim.TLSProperties {
	if config == nil {
		return shim.TLSProperties{
			Disabled: true,
		}
	}

	props := shim.TLSProperties{
		Disabled: false,
	}

	// Read certificate files for shim.TLSProperties
	keyPath := os.Getenv("CHAINCODE_TLS_KEY")
	certPath := os.Getenv("CHAINCODE_TLS_CERT")

	if keyPath != "" {
		key, err := os.ReadFile(keyPath)
		if err == nil {
			props.Key = key
		}
	}

	if certPath != "" {
		cert, err := os.ReadFile(certPath)
		if err == nil {
			props.Cert = cert
		}
	}

	clientCACertPath := os.Getenv("CHAINCODE_TLS_CLIENT_CA_CERT")
	if clientCACertPath != "" {
		clientCA, err := os.ReadFile(clientCACertPath)
		if err == nil {
			props.ClientCACerts = clientCA
		}
	}

	return props
}
