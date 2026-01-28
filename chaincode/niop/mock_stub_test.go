// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package niop

import (
	"sort"
	"strings"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-chaincode-go/shimtest"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/hyperledger/fabric-protos-go/ledger/queryresult"
)

// enhancedMockStub wraps shimtest.MockStub to provide GetPrivateDataByRange support.
// The standard MockStub doesn't implement this method, which is needed for testing
// range queries on private data collections.
type enhancedMockStub struct {
	*shimtest.MockStub
	privateData map[string]map[string][]byte // collection -> key -> value
}

// newEnhancedMockStub creates a new enhanced mock stub with private data range support.
func newEnhancedMockStub(name string) *enhancedMockStub {
	return &enhancedMockStub{
		MockStub:    shimtest.NewMockStub(name, nil),
		privateData: make(map[string]map[string][]byte),
	}
}

// PutPrivateData stores data in a private collection.
// Overrides MockStub to track data for range queries.
func (e *enhancedMockStub) PutPrivateData(collection string, key string, value []byte) error {
	if e.privateData[collection] == nil {
		e.privateData[collection] = make(map[string][]byte)
	}
	e.privateData[collection][key] = value
	// Also call the parent to maintain compatibility
	return e.MockStub.PutPrivateData(collection, key, value)
}

// GetPrivateData retrieves data from a private collection.
func (e *enhancedMockStub) GetPrivateData(collection string, key string) ([]byte, error) {
	if e.privateData[collection] == nil {
		return nil, nil
	}
	return e.privateData[collection][key], nil
}

// GetPrivateDataByRange implements range queries on private data.
// This is the key method that shimtest.MockStub doesn't implement.
func (e *enhancedMockStub) GetPrivateDataByRange(collection string, startKey string, endKey string) (shim.StateQueryIteratorInterface, error) {
	collectionData := e.privateData[collection]
	if collectionData == nil {
		return &mockKVIterator{keys: nil, values: nil}, nil
	}

	// Collect matching keys
	var keys []string
	for k := range collectionData {
		if startKey <= k && k < endKey {
			keys = append(keys, k)
		}
	}
	sort.Strings(keys)

	// Build values slice in key order
	values := make([][]byte, len(keys))
	for i, k := range keys {
		values[i] = collectionData[k]
	}

	return &mockKVIterator{keys: keys, values: values, index: 0}, nil
}

// mockKVIterator implements shim.StateQueryIteratorInterface for test results.
type mockKVIterator struct {
	keys   []string
	values [][]byte
	index  int
}

// HasNext returns true if the iterator has more results.
func (m *mockKVIterator) HasNext() bool {
	return m.index < len(m.keys)
}

// Next returns the next key-value pair.
func (m *mockKVIterator) Next() (*queryresult.KV, error) {
	if m.index >= len(m.keys) {
		return nil, nil
	}
	kv := &queryresult.KV{
		Key:   m.keys[m.index],
		Value: m.values[m.index],
	}
	m.index++
	return kv, nil
}

// Close closes the iterator.
func (m *mockKVIterator) Close() error {
	return nil
}

// GetStateByRange implements range queries on world state.
// This allows testing GetAllAgencies and similar functions.
func (e *enhancedMockStub) GetStateByRange(startKey string, endKey string) (shim.StateQueryIteratorInterface, error) {
	// MockStub.Keys is a *list.List, need to iterate it properly
	var keys []string

	// Iterate through all keys in the mock stub's state
	for element := e.MockStub.Keys.Front(); element != nil; element = element.Next() {
		key := element.Value.(string)
		if startKey <= key && (endKey == "" || key < endKey) {
			val, _ := e.MockStub.GetState(key)
			if val != nil {
				keys = append(keys, key)
			}
		}
	}

	sort.Strings(keys)
	// Build values slice in key order
	values := make([][]byte, len(keys))
	for i, k := range keys {
		val, _ := e.MockStub.GetState(k)
		values[i] = val
	}

	return &mockKVIterator{keys: keys, values: values, index: 0}, nil
}

// enhancedMockContext wraps the enhanced stub in a transaction context.
// It embeds the contractapi.TransactionContext to satisfy the interface
// but overrides GetStub to return our enhanced mock.
type enhancedMockContext struct {
	contractapi.TransactionContextInterface
	stub *enhancedMockStub
}

func (m *enhancedMockContext) GetStub() shim.ChaincodeStubInterface {
	return m.stub
}

// newEnhancedMockContext creates a new test context with range query support.
func newEnhancedMockContext() *enhancedMockContext {
	stub := newEnhancedMockStub("niop")
	stub.MockTransactionStart("test-tx")
	return &enhancedMockContext{stub: stub}
}

// Helper to check if a string starts with a prefix (for key filtering)
func hasKeyPrefix(key, prefix string) bool {
	return strings.HasPrefix(key, prefix)
}
