// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

//go:build integration

// Package integration provides end-to-end tests against a running Fabric network.
package integration

import (
	"os"
	"path/filepath"
)

// OrgConfig holds connection details for an organization.
type OrgConfig struct {
	MSPID           string
	CertPath        string // Admin user certificate
	KeyDir          string // Admin user private key directory
	TLSCertPath     string // Peer TLS CA certificate
	PeerEndpoint    string // host:port for gRPC connection
	GatewayPeerName string // peer hostname for TLS verification
}

// NetworkConfig returns organization configs for the local Docker Compose network.
// Environment variables can override default values for CI/CD flexibility.
func NetworkConfig() map[string]OrgConfig {
	cryptoBase := getCryptoConfigPath()

	return map[string]OrgConfig{
		"Org1": {
			MSPID:           "Org1MSP",
			CertPath:        filepath.Join(cryptoBase, "peerOrganizations/org1.tolling.network/users/Admin@org1.tolling.network/msp/signcerts/Admin@org1.tolling.network-cert.pem"),
			KeyDir:          filepath.Join(cryptoBase, "peerOrganizations/org1.tolling.network/users/Admin@org1.tolling.network/msp/keystore"),
			TLSCertPath:     filepath.Join(cryptoBase, "peerOrganizations/org1.tolling.network/peers/peer0.org1.tolling.network/tls/ca.crt"),
			PeerEndpoint:    getEnvOrDefault("ORG1_PEER_ENDPOINT", "localhost:7051"),
			GatewayPeerName: "peer0.org1.tolling.network",
		},
		"Org2": {
			MSPID:           "Org2MSP",
			CertPath:        filepath.Join(cryptoBase, "peerOrganizations/org2.tolling.network/users/Admin@org2.tolling.network/msp/signcerts/Admin@org2.tolling.network-cert.pem"),
			KeyDir:          filepath.Join(cryptoBase, "peerOrganizations/org2.tolling.network/users/Admin@org2.tolling.network/msp/keystore"),
			TLSCertPath:     filepath.Join(cryptoBase, "peerOrganizations/org2.tolling.network/peers/peer0.org2.tolling.network/tls/ca.crt"),
			PeerEndpoint:    getEnvOrDefault("ORG2_PEER_ENDPOINT", "localhost:8051"),
			GatewayPeerName: "peer0.org2.tolling.network",
		},
		"Org3": {
			MSPID:           "Org3MSP",
			CertPath:        filepath.Join(cryptoBase, "peerOrganizations/org3.tolling.network/users/Admin@org3.tolling.network/msp/signcerts/Admin@org3.tolling.network-cert.pem"),
			KeyDir:          filepath.Join(cryptoBase, "peerOrganizations/org3.tolling.network/users/Admin@org3.tolling.network/msp/keystore"),
			TLSCertPath:     filepath.Join(cryptoBase, "peerOrganizations/org3.tolling.network/peers/peer0.org3.tolling.network/tls/ca.crt"),
			PeerEndpoint:    getEnvOrDefault("ORG3_PEER_ENDPOINT", "localhost:9051"),
			GatewayPeerName: "peer0.org3.tolling.network",
		},
		"Org4": {
			MSPID:           "Org4MSP",
			CertPath:        filepath.Join(cryptoBase, "peerOrganizations/org4.tolling.network/users/Admin@org4.tolling.network/msp/signcerts/Admin@org4.tolling.network-cert.pem"),
			KeyDir:          filepath.Join(cryptoBase, "peerOrganizations/org4.tolling.network/users/Admin@org4.tolling.network/msp/keystore"),
			TLSCertPath:     filepath.Join(cryptoBase, "peerOrganizations/org4.tolling.network/peers/peer0.org4.tolling.network/tls/ca.crt"),
			PeerEndpoint:    getEnvOrDefault("ORG4_PEER_ENDPOINT", "localhost:10051"),
			GatewayPeerName: "peer0.org4.tolling.network",
		},
	}
}

// ChannelName returns the channel name for integration tests.
func ChannelName() string {
	return getEnvOrDefault("CHANNEL_NAME", "tolling")
}

// ChaincodeName returns the chaincode name for integration tests.
func ChaincodeName() string {
	return getEnvOrDefault("CHAINCODE_NAME", "niop")
}

// getCryptoConfigPath returns the path to crypto-config directory.
func getCryptoConfigPath() string {
	if path := os.Getenv("CRYPTO_CONFIG_PATH"); path != "" {
		return path
	}
	// Default: relative to integration test directory
	// When running from chaincode/integration/, go up to project root
	return "../../network-config/crypto-config"
}

func getEnvOrDefault(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
