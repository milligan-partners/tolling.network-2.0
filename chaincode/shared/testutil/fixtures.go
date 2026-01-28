// Copyright 2016-2026 Milligan Partners LLC. Apache-2.0 license.

package testutil

import (
	"encoding/json"
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

// testdataDir returns the absolute path to chaincode/testdata/.
// This works regardless of which chaincode package runs the test.
func testdataDir() string {
	_, filename, _, _ := runtime.Caller(0)
	return filepath.Join(filepath.Dir(filename), "..", "..", "testdata")
}

// LoadFixture reads a JSON file from chaincode/testdata/ and unmarshals it
// into dest. Fails the test if the file can't be read or parsed.
func LoadFixture(t *testing.T, filename string, dest interface{}) {
	t.Helper()
	path := filepath.Join(testdataDir(), filename)
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("failed to read fixture %q: %v", filename, err)
	}
	if err := json.Unmarshal(data, dest); err != nil {
		t.Fatalf("failed to parse fixture %q: %v", filename, err)
	}
}

// LoadFixtureBytes reads a raw file from chaincode/testdata/.
// Use for XML fixtures or non-JSON data.
func LoadFixtureBytes(t *testing.T, filename string) []byte {
	t.Helper()
	path := filepath.Join(testdataDir(), filename)
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("failed to read fixture %q: %v", filename, err)
	}
	return data
}

// FixturePath returns the absolute path to a file in chaincode/testdata/.
func FixturePath(filename string) string {
	return filepath.Join(testdataDir(), filename)
}

// SampleAgencies returns a standard set of test agency IDs
// matching the fixtures and docker-compose network.
var SampleAgencies = struct {
	TCA    string
	BATA   string
	SANDAG string
}{
	TCA:    "TCA",
	BATA:   "BATA",
	SANDAG: "SANDAG",
}

// SampleTag returns a minimal valid tag for testing.
func SampleTag() map[string]interface{} {
	return map[string]interface{}{
		"tagSerialNumber": "TEST.000000001",
		"tagAgencyID":     SampleAgencies.TCA,
		"homeAgencyID":    SampleAgencies.TCA,
		"accountID":       "A000000001",
		"tagStatus":       "valid",
		"tagType":         "single",
		"tagClass":        2,
		"tagProtocol":     "6c",
	}
}

// SampleCharge returns a minimal valid charge for testing.
func SampleCharge() map[string]interface{} {
	return map[string]interface{}{
		"chargeID":        "CHG-TEST-001",
		"chargeType":      "toll_tag",
		"recordType":      "TB01",
		"protocol":        "niop",
		"awayAgencyID":    SampleAgencies.BATA,
		"homeAgencyID":    SampleAgencies.TCA,
		"tagSerialNumber": "TEST.000000001",
		"facilityID":      "SR73",
		"plaza":           "CATALINA",
		"exitDateTime":    "2026-01-15T08:30:00Z",
		"vehicleClass":    2,
		"amount":          4.75,
		"fee":             0.05,
		"netAmount":       4.70,
		"status":          "pending",
	}
}

// SampleReconciliation returns a minimal valid reconciliation for testing.
func SampleReconciliation() map[string]interface{} {
	return map[string]interface{}{
		"reconciliationID":   "RECON-TEST-001",
		"chargeID":           "CHG-TEST-001",
		"homeAgencyID":       SampleAgencies.TCA,
		"postingDisposition": "P",
		"postedAmount":       4.75,
		"postedDateTime":     "2026-01-15T10:00:00Z",
		"adjustmentCount":    0,
		"flatFee":            0.05,
		"percentFee":         0.0,
	}
}

// SampleCorrection returns a minimal valid correction for testing.
func SampleCorrection() map[string]interface{} {
	return map[string]interface{}{
		"correctionID":     "CORR-TEST-001",
		"originalChargeID": "CHG-TEST-001",
		"correctionSeqNo":  1,
		"correctionReason": "C",
		"fromAgencyID":     SampleAgencies.BATA,
		"toAgencyID":       SampleAgencies.TCA,
		"recordType":       "TB01A",
		"amount":           3.50,
	}
}

// SampleAcknowledgement returns a minimal valid acknowledgement for testing.
func SampleAcknowledgement() map[string]interface{} {
	return map[string]interface{}{
		"acknowledgementID": "ACK-TEST-001",
		"submissionType":    "STVL",
		"fromAgencyID":      SampleAgencies.TCA,
		"toAgencyID":        SampleAgencies.BATA,
		"returnCode":        "00",
		"returnMessage":     "Success",
	}
}

// SampleSettlement returns a minimal valid settlement for testing.
func SampleSettlement() map[string]interface{} {
	return map[string]interface{}{
		"settlementID":    "SETTLE-TEST-001",
		"periodStart":     "2026-01-01",
		"periodEnd":       "2026-01-31",
		"payorAgencyID":   SampleAgencies.TCA,
		"payeeAgencyID":   SampleAgencies.BATA,
		"grossAmount":     15000.00,
		"totalFees":       150.00,
		"netAmount":       14850.00,
		"chargeCount":     3000,
		"correctionCount": 15,
		"status":          "draft",
	}
}

// SampleAgency returns a minimal valid agency for testing.
func SampleAgency() map[string]interface{} {
	return map[string]interface{}{
		"agencyID":         SampleAgencies.TCA,
		"name":             "Transportation Corridor Agencies",
		"consortium":       []string{"WRTO"},
		"state":            "CA",
		"role":             "toll_operator",
		"connectivityMode": "direct",
		"status":           "active",
		"capabilities":     []string{"toll"},
		"protocolSupport":  []string{"ctoc_rev_a"},
	}
}

// PostingDispositions maps codes to descriptions for test assertions.
var PostingDispositions = map[string]string{
	"P": "Posted successfully",
	"D": "Duplicate transaction",
	"I": "Invalid tag or plate",
	"N": "Not posted (general)",
	"S": "System or communication issue",
	"T": "Transaction content/format error",
	"C": "Tag/plate not on file",
	"O": "Transaction too old",
}

// NIOPRecordTypes lists valid NIOP ICD record types.
var NIOPRecordTypes = []string{"TB01", "TC01", "TC02", "VB01", "VC01", "VC02"}

// NIOPCorrectionRecordTypes lists valid correction record types (suffix A).
var NIOPCorrectionRecordTypes = []string{"TB01A", "TC01A", "TC02A", "VB01A", "VC01A", "VC02A"}

// TagStatuses lists valid tag status values.
var TagStatuses = []string{"valid", "invalid", "inactive", "lost", "stolen"}

// ChargeStatuses lists valid charge lifecycle states.
var ChargeStatuses = []string{"pending", "posted", "disputed", "rejected", "settled"}

// SettlementStatuses lists valid settlement lifecycle states.
var SettlementStatuses = []string{"draft", "submitted", "accepted", "disputed", "paid"}

// AckReturnCodes maps NIOP acknowledgement codes.
var AckReturnCodes = map[string]string{
	"00": "Success",
	"01": "Invalid submission type",
	"02": "Invalid agency ID",
	"03": "Sequence number error",
	"04": "Record count mismatch",
	"05": "Duplicate submission",
	"06": "Format error",
	"07": "System error",
	"08": "Unauthorized",
	"09": "Invalid date range",
	"10": "File too large",
	"11": "Partial acceptance",
	"12": "Rejected",
	"13": "Unknown error",
}
