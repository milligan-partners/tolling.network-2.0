#!/bin/bash
#
# integration-test.sh
#
# Runs integration tests against the local Fabric network.
#
# Prerequisites:
#   - Network running (make docker-up)
#   - Channel created (make channel-create)
#   - Chaincode deployed (make chaincode-deploy)
#   - Go installed
#
# Usage:
#   ./integration-test.sh [OPTIONS]
#
# Options:
#   -h, --help      Show this help message
#   -v, --verbose   Enable verbose output
#   --skip-checks   Skip network health checks
#
# Copyright 2016-2026 Milligan Partners LLC
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INTEGRATION_DIR="${PROJECT_ROOT}/chaincode/integration"
CRYPTO_CONFIG_PATH="${PROJECT_ROOT}/network-config/crypto-config"

VERBOSE="${VERBOSE:-false}"
SKIP_CHECKS="${SKIP_CHECKS:-false}"

# Channel and chaincode defaults
CHANNEL_NAME="${CHANNEL_NAME:-tolling}"
CHAINCODE_NAME="${CHAINCODE_NAME:-niop}"

# ==============================================================================
# Logging Functions
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_verbose() {
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "[VERBOSE] $*"
    fi
}

# ==============================================================================
# Usage
# ==============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run integration tests against the local Fabric network.

Options:
  -h, --help      Show this help message
  -v, --verbose   Enable verbose output
  --skip-checks   Skip network health checks

Prerequisites:
  - Network running (make docker-up)
  - Channel created (make channel-create)
  - Chaincode deployed (make chaincode-deploy)
  - Go installed

Environment Variables:
  CHANNEL_NAME      Channel name (default: tolling)
  CHAINCODE_NAME    Chaincode name (default: niop)
  CRYPTO_CONFIG_PATH  Path to crypto-config (default: network-config/crypto-config)

Examples:
  $(basename "$0")
  $(basename "$0") --verbose
  $(basename "$0") --skip-checks
EOF
}

# ==============================================================================
# Prerequisite Checks
# ==============================================================================

check_go() {
    if ! command -v go &> /dev/null; then
        log_error "Go is not installed or not in PATH"
        log_error "Please install Go 1.24+ from https://golang.org/dl/"
        exit 1
    fi

    local go_version
    go_version=$(go version | grep -oP 'go\d+\.\d+' | head -1)
    log_verbose "Found Go: ${go_version}"
}

check_network() {
    log_info "Checking network health..."

    # List of expected containers
    local containers=(
        "orderer1.orderer.tolling.network"
        "peer0.org1.tolling.network"
        "peer0.org2.tolling.network"
        "peer0.org3.tolling.network"
        "peer0.org4.tolling.network"
        "couchdb0"
        "couchdb1"
        "couchdb2"
        "couchdb3"
    )

    local missing=()
    for container in "${containers[@]}"; do
        if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
            missing+=("${container}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing containers: ${missing[*]}"
        log_error "Run: make docker-up"
        exit 1
    fi

    log_success "All network containers are running"
}

check_crypto_config() {
    log_info "Checking crypto configuration..."

    if [[ ! -d "${CRYPTO_CONFIG_PATH}" ]]; then
        log_error "Crypto config not found: ${CRYPTO_CONFIG_PATH}"
        log_error "Run: make network-init"
        exit 1
    fi

    # Check for at least one org's admin credentials
    local admin_cert="${CRYPTO_CONFIG_PATH}/peerOrganizations/org1.tolling.network/users/Admin@org1.tolling.network/msp/signcerts/Admin@org1.tolling.network-cert.pem"
    if [[ ! -f "${admin_cert}" ]]; then
        log_error "Admin certificate not found: ${admin_cert}"
        log_error "Run: make network-init"
        exit 1
    fi

    log_success "Crypto configuration found"
}

check_chaincode() {
    log_info "Checking chaincode deployment..."

    # Use the CLI container to query chaincode
    local result
    result=$(docker exec cli peer lifecycle chaincode querycommitted \
        --channelID "${CHANNEL_NAME}" \
        --name "${CHAINCODE_NAME}" \
        --output json 2>&1) || true

    # When querying a specific chaincode by name, the response contains
    # "sequence" and "version" but not "name" (since we specified it in the query)
    if echo "${result}" | grep -q '"sequence":' && echo "${result}" | grep -q '"version":'; then
        log_success "Chaincode '${CHAINCODE_NAME}' is deployed on channel '${CHANNEL_NAME}'"
    else
        log_error "Chaincode '${CHAINCODE_NAME}' is not deployed"
        log_error "Run: make chaincode-deploy"
        exit 1
    fi
}

# ==============================================================================
# Run Tests
# ==============================================================================

run_tests() {
    log_info "Running integration tests..."
    echo ""

    cd "${INTEGRATION_DIR}"

    # Set environment variables for the tests
    export CRYPTO_CONFIG_PATH="${CRYPTO_CONFIG_PATH}"
    export CHANNEL_NAME="${CHANNEL_NAME}"
    export CHAINCODE_NAME="${CHAINCODE_NAME}"

    # Build test flags
    local test_flags="-v -tags=integration -timeout 10m"

    if [[ "${VERBOSE}" == "true" ]]; then
        test_flags="${test_flags} -count=1"  # Disable test caching
    fi

    # Run tests
    # shellcheck disable=SC2086
    if go test ${test_flags} ./...; then
        echo ""
        log_success "Integration tests completed successfully"
    else
        echo ""
        log_error "Integration tests failed"
        exit 1
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            --skip-checks)
                SKIP_CHECKS="true"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage >&2
                exit 1
                ;;
        esac
    done

    echo ""
    log_info "=============================================="
    log_info "Tolling.Network - Integration Tests"
    log_info "=============================================="
    log_info "Channel: ${CHANNEL_NAME}"
    log_info "Chaincode: ${CHAINCODE_NAME}"
    echo ""

    # Run prerequisite checks
    check_go

    if [[ "${SKIP_CHECKS}" != "true" ]]; then
        check_network
        check_crypto_config
        check_chaincode
    else
        log_warn "Skipping network health checks (--skip-checks)"
    fi

    echo ""

    # Run the tests
    run_tests
}

main "$@"
