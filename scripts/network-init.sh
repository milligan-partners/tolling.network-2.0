#!/bin/bash
#
# network-init.sh
#
# Generates cryptographic material and channel artifacts for the Tolling.Network
# Hyperledger Fabric 2.5.x development network.
#
# This script:
# - Generates crypto material using cryptogen
# - Generates genesis block using configtxgen
# - Generates channel transaction using configtxgen
# - Generates anchor peer updates for each organization
#
# Prerequisites:
# - cryptogen and configtxgen binaries in PATH (from Fabric 2.5.x)
# - network-config/crypto-config.yaml
# - network-config/configtx.yaml
#
# Usage:
#   ./network-init.sh [OPTIONS]
#
# Options:
#   -h, --help           Show this help message
#   -c, --channel NAME   Channel name (default: tolling)
#   -v, --verbose        Enable verbose output
#   --clean              Remove existing crypto material before generating
#
# Copyright 2016-2026 Milligan Partners LLC
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
NETWORK_CONFIG_DIR="${PROJECT_ROOT}/network-config"
CRYPTO_CONFIG_FILE="${NETWORK_CONFIG_DIR}/crypto-config.yaml"
CONFIGTX_FILE="${NETWORK_CONFIG_DIR}/configtx.yaml"

# Output directories
CRYPTO_OUTPUT_DIR="${NETWORK_CONFIG_DIR}/crypto-config"
ARTIFACTS_DIR="${NETWORK_CONFIG_DIR}/channel-artifacts"

# Default values
CHANNEL_NAME="${CHANNEL_NAME:-tolling}"
SYSTEM_CHANNEL_NAME="${SYSTEM_CHANNEL_NAME:-system-channel}"
VERBOSE="${VERBOSE:-false}"
CLEAN="${CLEAN:-false}"

# Organizations (must match configtx.yaml)
ORGS=("Org1" "Org2" "Org3" "Org4")

# ==============================================================================
# Logging Functions
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date +'%Y-%m-%d %H:%M:%S') $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date +'%Y-%m-%d %H:%M:%S') $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date +'%Y-%m-%d %H:%M:%S') $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date +'%Y-%m-%d %H:%M:%S') $*" >&2
}

log_verbose() {
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $(date +'%Y-%m-%d %H:%M:%S') $*"
    fi
}

# ==============================================================================
# Usage
# ==============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Generate cryptographic material and channel artifacts for Tolling.Network.

Options:
  -h, --help           Show this help message
  -c, --channel NAME   Channel name (default: ${CHANNEL_NAME})
  -v, --verbose        Enable verbose output
  --clean              Remove existing crypto material before generating

Environment Variables:
  CHANNEL_NAME         Channel name (default: tolling)
  SYSTEM_CHANNEL_NAME  System channel name (default: system-channel)
  VERBOSE              Enable verbose output (true/false)

Examples:
  $(basename "$0")
  $(basename "$0") --clean --verbose
  $(basename "$0") -c interop --verbose
  CHANNEL_NAME=national $(basename "$0")

Prerequisites:
  - cryptogen binary in PATH (Fabric 2.5.x)
  - configtxgen binary in PATH (Fabric 2.5.x)
EOF
}

# ==============================================================================
# Prerequisite Checks
# ==============================================================================

check_prerequisites() {
    log_info "Checking prerequisites..."
    local missing=()

    # Check for cryptogen
    if ! command -v cryptogen &> /dev/null; then
        missing+=("cryptogen")
    else
        log_verbose "Found cryptogen: $(command -v cryptogen)"
        if [[ "${VERBOSE}" == "true" ]]; then
            cryptogen version 2>/dev/null || true
        fi
    fi

    # Check for configtxgen
    if ! command -v configtxgen &> /dev/null; then
        missing+=("configtxgen")
    else
        log_verbose "Found configtxgen: $(command -v configtxgen)"
        if [[ "${VERBOSE}" == "true" ]]; then
            configtxgen -version 2>/dev/null || true
        fi
    fi

    # Check for required config files
    if [[ ! -f "${CRYPTO_CONFIG_FILE}" ]]; then
        log_error "crypto-config.yaml not found at ${CRYPTO_CONFIG_FILE}"
        missing+=("crypto-config.yaml")
    else
        log_verbose "Found crypto-config.yaml: ${CRYPTO_CONFIG_FILE}"
    fi

    if [[ ! -f "${CONFIGTX_FILE}" ]]; then
        log_error "configtx.yaml not found at ${CONFIGTX_FILE}"
        missing+=("configtx.yaml")
    else
        log_verbose "Found configtx.yaml: ${CONFIGTX_FILE}"
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing prerequisites: ${missing[*]}"
        echo ""
        echo "To install Fabric binaries:"
        echo "  curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.4 1.5.7"
        echo "  export PATH=\$PATH:/path/to/fabric-samples/bin"
        echo ""
        exit 1
    fi

    log_success "All prerequisites satisfied"
}

# ==============================================================================
# Cleanup Functions
# ==============================================================================

clean_crypto_material() {
    log_info "Cleaning existing crypto material..."

    if [[ -d "${CRYPTO_OUTPUT_DIR}" ]]; then
        log_verbose "Removing ${CRYPTO_OUTPUT_DIR}"
        rm -rf "${CRYPTO_OUTPUT_DIR}"
    fi

    if [[ -d "${ARTIFACTS_DIR}" ]]; then
        log_verbose "Removing ${ARTIFACTS_DIR}"
        rm -rf "${ARTIFACTS_DIR}"
    fi

    log_success "Cleanup complete"
}

# ==============================================================================
# Directory Setup
# ==============================================================================

setup_directories() {
    log_info "Setting up output directories..."

    mkdir -p "${CRYPTO_OUTPUT_DIR}"
    mkdir -p "${ARTIFACTS_DIR}"

    log_verbose "Created: ${CRYPTO_OUTPUT_DIR}"
    log_verbose "Created: ${ARTIFACTS_DIR}"

    log_success "Directories ready"
}

# ==============================================================================
# Generate Crypto Material
# ==============================================================================

generate_crypto_material() {
    log_info "Generating crypto material using cryptogen..."

    cryptogen generate \
        --config="${CRYPTO_CONFIG_FILE}" \
        --output="${CRYPTO_OUTPUT_DIR}"

    # Verify output
    local orderer_count peer_count
    orderer_count=$(find "${CRYPTO_OUTPUT_DIR}/ordererOrganizations" -name "*.pem" 2>/dev/null | wc -l)
    peer_count=$(find "${CRYPTO_OUTPUT_DIR}/peerOrganizations" -name "*.pem" 2>/dev/null | wc -l)

    log_verbose "Generated ${orderer_count} orderer certificates"
    log_verbose "Generated ${peer_count} peer certificates"

    if [[ ${orderer_count} -eq 0 ]] || [[ ${peer_count} -eq 0 ]]; then
        log_error "Crypto material generation may have failed - no certificates found"
        exit 1
    fi

    log_success "Crypto material generated at ${CRYPTO_OUTPUT_DIR}"
}

# ==============================================================================
# Generate Genesis Block
# ==============================================================================

generate_genesis_block() {
    log_info "Generating genesis block for system channel..."

    # Set FABRIC_CFG_PATH for configtxgen
    export FABRIC_CFG_PATH="${NETWORK_CONFIG_DIR}"

    configtxgen \
        -profile TollingGenesis \
        -channelID "${SYSTEM_CHANNEL_NAME}" \
        -outputBlock "${ARTIFACTS_DIR}/genesis.block"

    if [[ ! -f "${ARTIFACTS_DIR}/genesis.block" ]]; then
        log_error "Failed to generate genesis block"
        exit 1
    fi

    local size
    size=$(du -h "${ARTIFACTS_DIR}/genesis.block" | cut -f1)
    log_verbose "Genesis block size: ${size}"

    log_success "Genesis block generated at ${ARTIFACTS_DIR}/genesis.block"
}

# ==============================================================================
# Generate Channel Transaction
# ==============================================================================

generate_channel_tx() {
    log_info "Generating channel transaction for '${CHANNEL_NAME}'..."

    export FABRIC_CFG_PATH="${NETWORK_CONFIG_DIR}"

    configtxgen \
        -profile TollingChannel \
        -outputCreateChannelTx "${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx" \
        -channelID "${CHANNEL_NAME}"

    if [[ ! -f "${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx" ]]; then
        log_error "Failed to generate channel transaction"
        exit 1
    fi

    log_success "Channel transaction generated at ${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx"
}

# ==============================================================================
# Generate Anchor Peer Updates
# ==============================================================================

generate_anchor_peer_updates() {
    log_info "Generating anchor peer updates for all organizations..."

    export FABRIC_CFG_PATH="${NETWORK_CONFIG_DIR}"

    for org in "${ORGS[@]}"; do
        local msp_id="${org}MSP"
        local output_file="${ARTIFACTS_DIR}/${msp_id}anchors.tx"

        log_verbose "Generating anchor peer update for ${msp_id}..."

        configtxgen \
            -profile TollingChannel \
            -outputAnchorPeersUpdate "${output_file}" \
            -channelID "${CHANNEL_NAME}" \
            -asOrg "${msp_id}"

        if [[ ! -f "${output_file}" ]]; then
            log_error "Failed to generate anchor peer update for ${msp_id}"
            exit 1
        fi

        log_verbose "Created ${output_file}"
    done

    log_success "Anchor peer updates generated for: ${ORGS[*]}"
}

# ==============================================================================
# Summary
# ==============================================================================

print_summary() {
    echo ""
    echo "=============================================================================="
    echo "                    Network Initialization Complete"
    echo "=============================================================================="
    echo ""
    echo "Generated artifacts:"
    echo ""
    echo "  Crypto Material:"
    echo "    ${CRYPTO_OUTPUT_DIR}/"
    echo ""
    echo "  Channel Artifacts:"
    ls -la "${ARTIFACTS_DIR}/" | tail -n +2 | while read -r line; do
        echo "    ${line}"
    done
    echo ""
    echo "Next steps:"
    echo "  1. Start the network:    docker-compose up -d"
    echo "  2. Create the channel:   ./scripts/create-channel.sh"
    echo "  3. Deploy chaincode:     ./scripts/deploy-chaincode.sh"
    echo ""
    echo "=============================================================================="
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
            -c|--channel)
                CHANNEL_NAME="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            --clean)
                CLEAN="true"
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
    log_info "Tolling.Network - Network Initialization"
    log_info "=============================================="
    log_info "Channel Name: ${CHANNEL_NAME}"
    log_info "System Channel: ${SYSTEM_CHANNEL_NAME}"
    log_info "Config Dir: ${NETWORK_CONFIG_DIR}"
    echo ""

    # Run initialization steps
    check_prerequisites

    if [[ "${CLEAN}" == "true" ]]; then
        clean_crypto_material
    fi

    setup_directories
    generate_crypto_material
    generate_genesis_block
    generate_channel_tx
    generate_anchor_peer_updates

    print_summary
}

main "$@"
