// Copyright 2016-2026 Milligan Partners. Apache-2.0 license.

// Package testutil provides shared test utilities for chaincode unit tests.
//
// This package wraps Fabric's ChaincodeStubInterface mock with helpers
// that reduce boilerplate in test files. All chaincode packages (niop, ctoc)
// import this package for consistent test setup.
package testutil

import (
	"encoding/json"
	"fmt"
	"testing"

	"github.com/hyperledger/fabric-chaincode-go/shimtest"
)

// NewMockStub creates a configured mock stub for chaincode testing.
// The name parameter identifies the chaincode in logs.
func NewMockStub(name string) *shimtest.MockStub {
	return shimtest.NewMockStub(name, nil)
}

// PutState is a test helper that marshals a value to JSON and puts it
// on the mock stub's state. Fails the test on marshal error.
func PutState(t *testing.T, stub *shimtest.MockStub, key string, value interface{}) {
	t.Helper()
	bytes, err := json.Marshal(value)
	if err != nil {
		t.Fatalf("failed to marshal state for key %q: %v", key, err)
	}
	err = stub.PutState(key, bytes)
	if err != nil {
		t.Fatalf("failed to put state for key %q: %v", key, err)
	}
}

// GetStateAs retrieves a key from the mock stub and unmarshals it into dest.
// Fails the test if the key doesn't exist or can't be unmarshaled.
func GetStateAs(t *testing.T, stub *shimtest.MockStub, key string, dest interface{}) {
	t.Helper()
	bytes, err := stub.GetState(key)
	if err != nil {
		t.Fatalf("failed to get state for key %q: %v", key, err)
	}
	if bytes == nil {
		t.Fatalf("state not found for key %q", key)
	}
	if err := json.Unmarshal(bytes, dest); err != nil {
		t.Fatalf("failed to unmarshal state for key %q: %v", key, err)
	}
}

// AssertStateExists checks that a key exists in the mock stub's state.
func AssertStateExists(t *testing.T, stub *shimtest.MockStub, key string) {
	t.Helper()
	bytes, err := stub.GetState(key)
	if err != nil {
		t.Fatalf("failed to get state for key %q: %v", key, err)
	}
	if bytes == nil {
		t.Errorf("expected state for key %q to exist, but it was nil", key)
	}
}

// AssertStateNotExists checks that a key does not exist in the mock stub's state.
func AssertStateNotExists(t *testing.T, stub *shimtest.MockStub, key string) {
	t.Helper()
	bytes, err := stub.GetState(key)
	if err != nil {
		t.Fatalf("failed to get state for key %q: %v", key, err)
	}
	if bytes != nil {
		t.Errorf("expected state for key %q to not exist, but got %s", key, string(bytes))
	}
}

// CompositeKey builds a Fabric composite key from object type and attributes.
// This mirrors how chaincode constructs keys for CouchDB queries.
func CompositeKey(objectType string, attributes ...string) string {
	key, _ := shimtest.NewMockStub("tmp", nil).CreateCompositeKey(objectType, attributes)
	return key
}

// MockTransactionContext sets up the stub with a mock transaction ID.
func MockTransactionContext(stub *shimtest.MockStub, txID string) {
	stub.MockTransactionStart(txID)
}

// MockTransactionEnd completes a mock transaction.
func MockTransactionEnd(stub *shimtest.MockStub, txID string) {
	stub.MockTransactionEnd(txID)
}

// MustJSON marshals a value to JSON bytes, panicking on error.
// Use only in test setup where failure should be fatal.
func MustJSON(v interface{}) []byte {
	b, err := json.Marshal(v)
	if err != nil {
		panic(fmt.Sprintf("MustJSON: %v", err))
	}
	return b
}
