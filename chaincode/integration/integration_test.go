// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

//go:build integration

package integration

import (
	"fmt"
	"os"
	"testing"
	"time"
)

// Global clients for all organizations - initialized in TestMain
var (
	org1Client *FabricClient
	org2Client *FabricClient
	org3Client *FabricClient
	org4Client *FabricClient
)

// TestMain sets up Fabric Gateway connections for all organizations before running tests.
// This is called once before any tests run and handles cleanup after all tests complete.
func TestMain(m *testing.M) {
	config := NetworkConfig()
	channelName := ChannelName()
	chaincodeName := ChaincodeName()

	fmt.Printf("Integration Test Setup\n")
	fmt.Printf("  Channel: %s\n", channelName)
	fmt.Printf("  Chaincode: %s\n", chaincodeName)
	fmt.Printf("  Orgs: Org1, Org2, Org3, Org4\n")
	fmt.Println()

	var err error

	// Connect Org1
	org1Client, err = NewFabricClient("Org1", config["Org1"], channelName, chaincodeName)
	if err != nil {
		fmt.Printf("Failed to connect as Org1: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("  Connected: Org1 -> %s\n", config["Org1"].PeerEndpoint)

	// Connect Org2
	org2Client, err = NewFabricClient("Org2", config["Org2"], channelName, chaincodeName)
	if err != nil {
		fmt.Printf("Failed to connect as Org2: %v\n", err)
		cleanup()
		os.Exit(1)
	}
	fmt.Printf("  Connected: Org2 -> %s\n", config["Org2"].PeerEndpoint)

	// Connect Org3
	org3Client, err = NewFabricClient("Org3", config["Org3"], channelName, chaincodeName)
	if err != nil {
		fmt.Printf("Failed to connect as Org3: %v\n", err)
		cleanup()
		os.Exit(1)
	}
	fmt.Printf("  Connected: Org3 -> %s\n", config["Org3"].PeerEndpoint)

	// Connect Org4
	org4Client, err = NewFabricClient("Org4", config["Org4"], channelName, chaincodeName)
	if err != nil {
		fmt.Printf("Failed to connect as Org4: %v\n", err)
		cleanup()
		os.Exit(1)
	}
	fmt.Printf("  Connected: Org4 -> %s\n", config["Org4"].PeerEndpoint)

	fmt.Println()
	fmt.Println("Running integration tests...")
	fmt.Println()

	// Run all tests
	code := m.Run()

	// Cleanup
	cleanup()

	os.Exit(code)
}

// cleanup closes all Gateway connections.
func cleanup() {
	if org1Client != nil {
		org1Client.Close()
	}
	if org2Client != nil {
		org2Client.Close()
	}
	if org3Client != nil {
		org3Client.Close()
	}
	if org4Client != nil {
		org4Client.Close()
	}
}

// uniqueID generates a unique identifier for test data to avoid collisions.
// Uses timestamp with millisecond precision plus a prefix.
func uniqueID(prefix string) string {
	return fmt.Sprintf("%s-%s", prefix, time.Now().Format("20060102150405.000"))
}

// TestConnectionHealth verifies all organization connections are working.
func TestConnectionHealth(t *testing.T) {
	t.Run("Org1_Connected", func(t *testing.T) {
		if org1Client == nil {
			t.Fatal("Org1 client is nil")
		}
		if org1Client.Gateway == nil {
			t.Fatal("Org1 gateway is nil")
		}
	})

	t.Run("Org2_Connected", func(t *testing.T) {
		if org2Client == nil {
			t.Fatal("Org2 client is nil")
		}
		if org2Client.Gateway == nil {
			t.Fatal("Org2 gateway is nil")
		}
	})

	t.Run("Org3_Connected", func(t *testing.T) {
		if org3Client == nil {
			t.Fatal("Org3 client is nil")
		}
		if org3Client.Gateway == nil {
			t.Fatal("Org3 gateway is nil")
		}
	})

	t.Run("Org4_Connected", func(t *testing.T) {
		if org4Client == nil {
			t.Fatal("Org4 client is nil")
		}
		if org4Client.Gateway == nil {
			t.Fatal("Org4 gateway is nil")
		}
	})
}
