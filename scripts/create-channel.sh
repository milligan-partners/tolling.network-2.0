#!/bin/bash
#
# create-channel.sh
#
# Creates an application channel and joins all peers to it for the Tolling.Network
# Hyperledger Fabric 2.5.x development network.
#
# This script:
# - Creates the tolling channel
# - Joins all 4 organization peers to the channel
# - Updates anchor peers for each organization
#
# Prerequisites:
# - Network must be running (docker-compose up)
# - Channel artifacts must be generated (./network-init.sh)
# - peer CLI tool in PATH
#
# Usage:
#   ./create-channel.sh [OPTIONS]
#
# Options:
#   -h, --help           Show this help message
#   -c, --channel NAME   Channel name (default: tolling)
#   -v, --verbose        Enable verbose output
#   --skip-anchor        Skip anchor peer updates
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
FABRIC_CONFIG_DIR="${PROJECT_ROOT}/config"  # Contains core.yaml, orderer.yaml
ARTIFACTS_DIR="${NETWORK_CONFIG_DIR}/channel-artifacts"
CRYPTO_DIR="${NETWORK_CONFIG_DIR}/crypto-config"

# Default values
CHANNEL_NAME="${CHANNEL_NAME:-tolling}"
VERBOSE="${VERBOSE:-false}"
SKIP_ANCHOR="${SKIP_ANCHOR:-false}"

# Network configuration
ORDERER_HOST="orderer1.orderer.tolling.network"
ORDERER_PORT="7050"
ORDERER_ADDRESS="${ORDERER_HOST}:${ORDERER_PORT}"
ORDERER_CA="${CRYPTO_DIR}/ordererOrganizations/orderer.tolling.network/orderers/orderer1.orderer.tolling.network/msp/tlscacerts/tlsca.orderer.tolling.network-cert.pem"

# CLI container name (using docker exec - required for hostname resolution)
CLI_CONTAINER="${CLI_CONTAINER:-cli}"

# Docker paths (inside CLI container) - matches docker-compose.yaml mounts
DOCKER_CRYPTO_DIR="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto"
DOCKER_ARTIFACTS_DIR="/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts"
DOCKER_CONFIG_DIR="/etc/hyperledger/fabric"

# Timeout for channel operations (seconds)
CHANNEL_TIMEOUT="${CHANNEL_TIMEOUT:-60}"
RETRY_DELAY="${RETRY_DELAY:-3}"
MAX_RETRIES="${MAX_RETRIES:-5}"

# Organization configurations
# Format: ORG_NAME:MSP_ID:PEER_HOST:PEER_PORT
declare -a ORG_CONFIGS=(
    "Org1:Org1MSP:peer0.org1.tolling.network:7051"
    "Org2:Org2MSP:peer0.org2.tolling.network:8051"
    "Org3:Org3MSP:peer0.org3.tolling.network:9051"
    "Org4:Org4MSP:peer0.org4.tolling.network:10051"
)

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

Create the tolling channel and join all peers.

Options:
  -h, --help           Show this help message
  -c, --channel NAME   Channel name (default: ${CHANNEL_NAME})
  -v, --verbose        Enable verbose output
  --skip-anchor        Skip anchor peer updates

Environment Variables:
  CHANNEL_NAME         Channel name (default: tolling)
  CHANNEL_TIMEOUT      Timeout for channel operations (default: 60)
  CLI_CONTAINER        CLI container name for docker exec (default: cli)

Examples:
  $(basename "$0")
  $(basename "$0") --verbose
  $(basename "$0") -c interop
  CHANNEL_NAME=national $(basename "$0")

Prerequisites:
  - Network running (docker-compose up)
  - Channel artifacts generated (./network-init.sh)
EOF
}

# ==============================================================================
# Prerequisite Checks
# ==============================================================================

check_prerequisites() {
    log_info "Checking prerequisites..."
    local missing=()

    # Always use docker exec - container hostnames can't be resolved from host
    # The CLI container has the proper network connectivity and crypto mounted
    if ! docker ps --format '{{.Names}}' | grep -q "^${CLI_CONTAINER}$"; then
        log_error "CLI container '${CLI_CONTAINER}' is not running"
        log_error "Start the network first: make docker-up"
        exit 1
    fi
    log_info "Using CLI container: ${CLI_CONTAINER}"

    # Check for channel artifacts
    if [[ ! -f "${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx" ]]; then
        log_error "Channel transaction not found: ${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx"
        missing+=("channel.tx")
    fi

    if [[ ! -f "${ARTIFACTS_DIR}/genesis.block" ]]; then
        log_error "Genesis block not found: ${ARTIFACTS_DIR}/genesis.block"
        missing+=("genesis.block")
    fi

    # Check for crypto material
    if [[ ! -d "${CRYPTO_DIR}" ]]; then
        log_error "Crypto material not found: ${CRYPTO_DIR}"
        missing+=("crypto-config")
    fi

    # Check anchor peer updates
    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r org_name msp_id _ _ <<< "${org_config}"
        local anchor_file="${ARTIFACTS_DIR}/${msp_id}anchors.tx"
        if [[ ! -f "${anchor_file}" ]]; then
            log_warn "Anchor peer update not found: ${anchor_file}"
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing prerequisites: ${missing[*]}"
        echo ""
        echo "Run ./scripts/network-init.sh first to generate artifacts"
        echo ""
        exit 1
    fi

    log_success "Prerequisites satisfied"
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# Build environment variables for a specific organization (for docker exec)
# Sets ORG_ENV_VARS array with -e flags for docker exec
set_org_env() {
    local org_name="$1"
    local msp_id="$2"
    local peer_host="$3"
    local peer_port="$4"

    local domain
    domain=$(echo "${org_name}" | tr '[:upper:]' '[:lower:]')

    # Store environment variables for docker exec
    CURRENT_MSP_ID="${msp_id}"
    CURRENT_PEER_ADDRESS="${peer_host}:${peer_port}"
    CURRENT_TLS_ROOTCERT="${DOCKER_CRYPTO_DIR}/peerOrganizations/${domain}.tolling.network/peers/${peer_host}/tls/ca.crt"
    CURRENT_MSP_PATH="${DOCKER_CRYPTO_DIR}/peerOrganizations/${domain}.tolling.network/users/Admin@${domain}.tolling.network/msp"

    log_verbose "Set environment for ${msp_id}:"
    log_verbose "  CORE_PEER_ADDRESS=${CURRENT_PEER_ADDRESS}"
    log_verbose "  CORE_PEER_LOCALMSPID=${CURRENT_MSP_ID}"
}

# Execute peer command via docker exec with retries
peer_with_retry() {
    local retries=0
    local result

    while [[ ${retries} -lt ${MAX_RETRIES} ]]; do
        if result=$(docker exec \
            -e CORE_PEER_LOCALMSPID="${CURRENT_MSP_ID}" \
            -e CORE_PEER_ADDRESS="${CURRENT_PEER_ADDRESS}" \
            -e CORE_PEER_TLS_ENABLED=true \
            -e CORE_PEER_TLS_ROOTCERT_FILE="${CURRENT_TLS_ROOTCERT}" \
            -e CORE_PEER_MSPCONFIGPATH="${CURRENT_MSP_PATH}" \
            -e FABRIC_CFG_PATH="${DOCKER_CONFIG_DIR}" \
            "${CLI_CONTAINER}" peer "$@" 2>&1); then
            echo "${result}"
            return 0
        fi

        retries=$((retries + 1))
        if [[ ${retries} -lt ${MAX_RETRIES} ]]; then
            log_warn "Command failed, retry ${retries}/${MAX_RETRIES} in ${RETRY_DELAY}s..."
            sleep "${RETRY_DELAY}"
        fi
    done

    log_error "Command failed after ${MAX_RETRIES} retries"
    echo "${result}"
    return 1
}

# ==============================================================================
# Channel Operations
# ==============================================================================

create_channel() {
    log_info "Creating channel '${CHANNEL_NAME}'..."

    # Use first org to create the channel
    IFS=':' read -r org_name msp_id peer_host peer_port <<< "${ORG_CONFIGS[0]}"
    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    # Docker paths for artifacts and crypto
    local docker_channel_tx="${DOCKER_ARTIFACTS_DIR}/${CHANNEL_NAME}.tx"
    local docker_channel_block="${DOCKER_ARTIFACTS_DIR}/${CHANNEL_NAME}.block"
    local docker_orderer_ca="${DOCKER_CRYPTO_DIR}/ordererOrganizations/orderer.tolling.network/orderers/orderer1.orderer.tolling.network/msp/tlscacerts/tlsca.orderer.tolling.network-cert.pem"

    log_verbose "Creating channel from ${docker_channel_tx}"

    peer_with_retry channel create \
        -o "${ORDERER_ADDRESS}" \
        -c "${CHANNEL_NAME}" \
        -f "${docker_channel_tx}" \
        --outputBlock "${docker_channel_block}" \
        --tls \
        --cafile "${docker_orderer_ca}" \
        --timeout "${CHANNEL_TIMEOUT}s"

    # Check if block was created (on host filesystem)
    if [[ ! -f "${ARTIFACTS_DIR}/${CHANNEL_NAME}.block" ]]; then
        log_error "Failed to create channel - block file not found"
        exit 1
    fi

    log_success "Channel '${CHANNEL_NAME}' created successfully"
}

join_channel() {
    local org_name="$1"
    local msp_id="$2"
    local peer_host="$3"
    local peer_port="$4"

    log_info "Joining ${peer_host} to channel '${CHANNEL_NAME}'..."

    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    local docker_channel_block="${DOCKER_ARTIFACTS_DIR}/${CHANNEL_NAME}.block"

    peer_with_retry channel join \
        -b "${docker_channel_block}"

    log_success "${peer_host} joined channel '${CHANNEL_NAME}'"
}

join_all_peers() {
    log_info "Joining all peers to channel '${CHANNEL_NAME}'..."

    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r org_name msp_id peer_host peer_port <<< "${org_config}"
        join_channel "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"
    done

    log_success "All peers joined channel '${CHANNEL_NAME}'"
}

update_anchor_peer() {
    local org_name="$1"
    local msp_id="$2"
    local peer_host="$3"
    local peer_port="$4"

    local anchor_file="${ARTIFACTS_DIR}/${msp_id}anchors.tx"

    if [[ ! -f "${anchor_file}" ]]; then
        log_warn "Anchor peer update file not found for ${msp_id}, skipping"
        return 0
    fi

    log_info "Updating anchor peer for ${msp_id}..."

    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    local docker_anchor_file="${DOCKER_ARTIFACTS_DIR}/${msp_id}anchors.tx"
    local docker_orderer_ca="${DOCKER_CRYPTO_DIR}/ordererOrganizations/orderer.tolling.network/orderers/orderer1.orderer.tolling.network/msp/tlscacerts/tlsca.orderer.tolling.network-cert.pem"

    peer_with_retry channel update \
        -o "${ORDERER_ADDRESS}" \
        -c "${CHANNEL_NAME}" \
        -f "${docker_anchor_file}" \
        --tls \
        --cafile "${docker_orderer_ca}"

    log_success "Anchor peer updated for ${msp_id}"
}

update_all_anchor_peers() {
    if [[ "${SKIP_ANCHOR}" == "true" ]]; then
        log_info "Skipping anchor peer updates (--skip-anchor)"
        return 0
    fi

    log_info "Updating anchor peers for all organizations..."

    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r org_name msp_id peer_host peer_port <<< "${org_config}"
        update_anchor_peer "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"
    done

    log_success "All anchor peers updated"
}

# ==============================================================================
# Verification
# ==============================================================================

verify_channel() {
    log_info "Verifying channel membership..."

    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r org_name msp_id peer_host peer_port <<< "${org_config}"
        set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

        local channels
        channels=$(peer channel list 2>&1)

        if echo "${channels}" | grep -q "${CHANNEL_NAME}"; then
            log_verbose "${peer_host} is member of '${CHANNEL_NAME}'"
        else
            log_warn "${peer_host} may not be joined to '${CHANNEL_NAME}'"
        fi
    done

    log_success "Channel verification complete"
}

# ==============================================================================
# Summary
# ==============================================================================

print_summary() {
    echo ""
    echo "=============================================================================="
    echo "                    Channel Creation Complete"
    echo "=============================================================================="
    echo ""
    echo "Channel: ${CHANNEL_NAME}"
    echo ""
    echo "Joined Peers:"
    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r _ msp_id peer_host peer_port <<< "${org_config}"
        echo "  - ${peer_host}:${peer_port} (${msp_id})"
    done
    echo ""
    echo "Channel Block: ${ARTIFACTS_DIR}/${CHANNEL_NAME}.block"
    echo ""
    echo "Next steps:"
    echo "  1. Deploy chaincode:  ./scripts/deploy-chaincode.sh"
    echo "  2. Test chaincode:    peer chaincode query ..."
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
            --skip-anchor)
                SKIP_ANCHOR="true"
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
    log_info "Tolling.Network - Channel Creation"
    log_info "=============================================="
    log_info "Channel Name: ${CHANNEL_NAME}"
    log_info "Orderer: ${ORDERER_ADDRESS}"
    echo ""

    # Run channel operations
    check_prerequisites
    create_channel
    join_all_peers
    update_all_anchor_peers
    verify_channel

    print_summary
}

main "$@"
