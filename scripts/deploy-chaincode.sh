#!/bin/bash
#
# deploy-chaincode.sh
#
# Deploys chaincode to the Tolling.Network Hyperledger Fabric 2.5.x network
# using the Fabric 2.x chaincode lifecycle.
#
# This script:
# - Packages the chaincode
# - Installs on all 4 organization peers
# - Approves for each organization
# - Commits the chaincode definition
# - Verifies deployment
#
# Fabric 2.x Lifecycle Steps:
# 1. peer lifecycle chaincode package
# 2. peer lifecycle chaincode install (on each peer)
# 3. peer lifecycle chaincode approveformyorg (for each org)
# 4. peer lifecycle chaincode commit
# 5. peer lifecycle chaincode querycommitted (verify)
#
# Prerequisites:
# - Network must be running
# - Channel must be created and all peers joined
# - peer CLI tool in PATH
#
# Usage:
#   ./deploy-chaincode.sh [OPTIONS]
#
# Options:
#   -h, --help              Show this help message
#   -n, --name NAME         Chaincode name (default: niop)
#   -v, --version VERSION   Chaincode version (default: 1.0)
#   -s, --sequence SEQ      Chaincode sequence (default: 1)
#   -c, --channel NAME      Channel name (default: tolling)
#   -p, --path PATH         Chaincode source path (default: chaincode/niop)
#   -l, --lang LANG         Chaincode language (default: golang)
#   --init-required         Require chaincode initialization
#   --verbose               Enable verbose output
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
CRYPTO_DIR="${NETWORK_CONFIG_DIR}/crypto-config"
COLLECTIONS_CONFIG="${NETWORK_CONFIG_DIR}/collections/collections_config.json"

# Default values
CC_NAME="${CC_NAME:-niop}"
CC_VERSION="${CC_VERSION:-1.0}"
CC_SEQUENCE="${CC_SEQUENCE:-1}"
CHANNEL_NAME="${CHANNEL_NAME:-tolling}"
CC_SRC_PATH="${CC_SRC_PATH:-${PROJECT_ROOT}/chaincode/niop}"
CC_LANG="${CC_LANG:-golang}"
CC_INIT_REQUIRED="${CC_INIT_REQUIRED:-false}"
VERBOSE="${VERBOSE:-false}"

# Package output directory
PACKAGE_DIR="${PROJECT_ROOT}/chaincode/packages"
CC_PACKAGE="${PACKAGE_DIR}/${CC_NAME}_${CC_VERSION}.tar.gz"

# Network configuration
ORDERER_HOST="orderer1.orderer.tolling.network"
ORDERER_PORT="7050"
ORDERER_ADDRESS="${ORDERER_HOST}:${ORDERER_PORT}"
ORDERER_CA="${CRYPTO_DIR}/ordererOrganizations/orderer.tolling.network/orderers/orderer1.orderer.tolling.network/msp/tlscacerts/tlsca.orderer.tolling.network-cert.pem"

# Timeout for operations
COMMIT_TIMEOUT="${COMMIT_TIMEOUT:-120}"
RETRY_DELAY="${RETRY_DELAY:-5}"
MAX_RETRIES="${MAX_RETRIES:-5}"

# Organization configurations
# Format: ORG_NAME:MSP_ID:PEER_HOST:PEER_PORT
declare -a ORG_CONFIGS=(
    "Org1:Org1MSP:peer0.org1.tolling.network:7051"
    "Org2:Org2MSP:peer0.org2.tolling.network:8051"
    "Org3:Org3MSP:peer0.org3.tolling.network:9051"
    "Org4:Org4MSP:peer0.org4.tolling.network:10051"
)

# Track package IDs per org
declare -A PACKAGE_IDS

# ==============================================================================
# Logging Functions
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
        echo -e "${CYAN}[VERBOSE]${NC} $(date +'%Y-%m-%d %H:%M:%S') $*"
    fi
}

log_step() {
    echo -e "${GREEN}[STEP]${NC} $*"
}

# ==============================================================================
# Usage
# ==============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Deploy chaincode to the Tolling.Network using Fabric 2.x lifecycle.

Options:
  -h, --help              Show this help message
  -n, --name NAME         Chaincode name (default: ${CC_NAME})
  -v, --version VERSION   Chaincode version (default: ${CC_VERSION})
  -s, --sequence SEQ      Chaincode sequence (default: ${CC_SEQUENCE})
  -c, --channel NAME      Channel name (default: ${CHANNEL_NAME})
  -p, --path PATH         Chaincode source path (default: chaincode/niop)
  -l, --lang LANG         Chaincode language: golang, node, java (default: ${CC_LANG})
  --init-required         Require chaincode initialization
  --verbose               Enable verbose output

Environment Variables:
  CC_NAME                 Chaincode name
  CC_VERSION              Chaincode version
  CC_SEQUENCE             Chaincode sequence number
  CHANNEL_NAME            Channel name
  CC_SRC_PATH             Chaincode source path
  CC_LANG                 Chaincode language

Examples:
  $(basename "$0")
  $(basename "$0") -n niop -v 1.0 -s 1
  $(basename "$0") --name ctoc --version 2.0 --sequence 2
  $(basename "$0") -p chaincode/ctoc -l golang --verbose

Chaincode Lifecycle Steps:
  1. Package chaincode
  2. Install on all peers
  3. Approve for each organization
  4. Commit chaincode definition
  5. Query committed to verify

Prerequisites:
  - Network running (docker-compose up)
  - Channel created (./create-channel.sh)
  - Chaincode source exists
EOF
}

# ==============================================================================
# Prerequisite Checks
# ==============================================================================

check_prerequisites() {
    log_info "Checking prerequisites..."
    local missing=()

    # Check for peer CLI
    if ! command -v peer &> /dev/null; then
        log_error "peer CLI not found in PATH"
        missing+=("peer CLI")
    else
        log_verbose "Found peer CLI: $(command -v peer)"
    fi

    # Check for chaincode source
    if [[ ! -d "${CC_SRC_PATH}" ]]; then
        log_error "Chaincode source not found: ${CC_SRC_PATH}"
        missing+=("chaincode source")
    else
        log_verbose "Found chaincode source: ${CC_SRC_PATH}"
    fi

    # Check for collections config if exists
    if [[ -f "${COLLECTIONS_CONFIG}" ]]; then
        log_verbose "Found collections config: ${COLLECTIONS_CONFIG}"
    else
        log_warn "Collections config not found: ${COLLECTIONS_CONFIG}"
        log_warn "Chaincode will be deployed without private data collections"
        COLLECTIONS_CONFIG=""
    fi

    # Check for crypto material
    if [[ ! -d "${CRYPTO_DIR}" ]]; then
        log_error "Crypto material not found: ${CRYPTO_DIR}"
        missing+=("crypto-config")
    fi

    # Check for go.mod in golang chaincode
    if [[ "${CC_LANG}" == "golang" ]] && [[ ! -f "${CC_SRC_PATH}/go.mod" ]]; then
        log_error "go.mod not found in chaincode source (required for Fabric 2.x)"
        missing+=("go.mod")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing prerequisites: ${missing[*]}"
        exit 1
    fi

    log_success "Prerequisites satisfied"
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# Set environment variables for a specific organization
set_org_env() {
    local org_name="$1"
    local msp_id="$2"
    local peer_host="$3"
    local peer_port="$4"

    export CORE_PEER_LOCALMSPID="${msp_id}"
    export CORE_PEER_ADDRESS="${peer_host}:${peer_port}"
    export CORE_PEER_TLS_ENABLED="true"

    local domain
    domain=$(echo "${org_name}" | tr '[:upper:]' '[:lower:]')
    export CORE_PEER_TLS_ROOTCERT_FILE="${CRYPTO_DIR}/peerOrganizations/${domain}.tolling.network/peers/${peer_host}/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="${CRYPTO_DIR}/peerOrganizations/${domain}.tolling.network/users/Admin@${domain}.tolling.network/msp"

    log_verbose "Set environment for ${msp_id}:"
    log_verbose "  CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}"
    log_verbose "  CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
}

# Execute peer command with retries
peer_with_retry() {
    local retries=0
    local result

    while [[ ${retries} -lt ${MAX_RETRIES} ]]; do
        if result=$(peer "$@" 2>&1); then
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
# Chaincode Lifecycle Operations
# ==============================================================================

# Step 1: Package chaincode
package_chaincode() {
    log_step "Step 1: Packaging chaincode..."

    # Create package directory
    mkdir -p "${PACKAGE_DIR}"

    # Check if package already exists
    if [[ -f "${CC_PACKAGE}" ]]; then
        log_warn "Package already exists: ${CC_PACKAGE}"
        log_warn "Using existing package (delete to force rebuild)"
        return 0
    fi

    log_info "Packaging ${CC_NAME} version ${CC_VERSION}..."
    log_verbose "Source: ${CC_SRC_PATH}"
    log_verbose "Output: ${CC_PACKAGE}"

    # For golang, vendor dependencies first
    if [[ "${CC_LANG}" == "golang" ]]; then
        log_verbose "Vendoring Go dependencies..."
        (cd "${CC_SRC_PATH}" && GO111MODULE=on go mod vendor 2>/dev/null || true)
    fi

    peer lifecycle chaincode package "${CC_PACKAGE}" \
        --path "${CC_SRC_PATH}" \
        --lang "${CC_LANG}" \
        --label "${CC_NAME}_${CC_VERSION}"

    if [[ ! -f "${CC_PACKAGE}" ]]; then
        log_error "Failed to create chaincode package"
        exit 1
    fi

    local size
    size=$(du -h "${CC_PACKAGE}" | cut -f1)
    log_success "Chaincode packaged: ${CC_PACKAGE} (${size})"
}

# Step 2: Install chaincode on a peer
install_chaincode() {
    local org_name="$1"
    local msp_id="$2"
    local peer_host="$3"
    local peer_port="$4"

    log_info "Installing chaincode on ${peer_host}..."

    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    local result
    result=$(peer_with_retry lifecycle chaincode install "${CC_PACKAGE}")

    # Extract package ID from output
    local package_id
    package_id=$(echo "${result}" | grep -oP 'Chaincode code package identifier: \K[^\s]+' || \
                 echo "${result}" | grep -oP 'Package ID: \K[^\s]+' || \
                 echo "")

    if [[ -z "${package_id}" ]]; then
        # Query installed to get package ID
        local query_result
        query_result=$(peer lifecycle chaincode queryinstalled 2>&1)
        package_id=$(echo "${query_result}" | grep "${CC_NAME}_${CC_VERSION}" | grep -oP 'Package ID: \K[^,]+' | head -1 || echo "")
    fi

    if [[ -z "${package_id}" ]]; then
        log_error "Failed to get package ID for ${msp_id}"
        exit 1
    fi

    PACKAGE_IDS["${msp_id}"]="${package_id}"
    log_verbose "Package ID for ${msp_id}: ${package_id}"
    log_success "Chaincode installed on ${peer_host}"
}

install_on_all_peers() {
    log_step "Step 2: Installing chaincode on all peers..."

    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r org_name msp_id peer_host peer_port <<< "${org_config}"
        install_chaincode "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"
    done

    log_success "Chaincode installed on all peers"
}

# Step 3: Approve chaincode for an organization
approve_chaincode() {
    local org_name="$1"
    local msp_id="$2"
    local peer_host="$3"
    local peer_port="$4"

    log_info "Approving chaincode for ${msp_id}..."

    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    local package_id="${PACKAGE_IDS[${msp_id}]}"

    if [[ -z "${package_id}" ]]; then
        log_error "No package ID found for ${msp_id}"
        exit 1
    fi

    # Build approve command
    local approve_cmd=(
        peer lifecycle chaincode approveformyorg
        -o "${ORDERER_ADDRESS}"
        --channelID "${CHANNEL_NAME}"
        --name "${CC_NAME}"
        --version "${CC_VERSION}"
        --package-id "${package_id}"
        --sequence "${CC_SEQUENCE}"
        --tls
        --cafile "${ORDERER_CA}"
    )

    # Add collections config if available
    if [[ -n "${COLLECTIONS_CONFIG}" ]] && [[ -f "${COLLECTIONS_CONFIG}" ]]; then
        approve_cmd+=(--collections-config "${COLLECTIONS_CONFIG}")
    fi

    # Add init required flag if set
    if [[ "${CC_INIT_REQUIRED}" == "true" ]]; then
        approve_cmd+=(--init-required)
    fi

    log_verbose "Approve command: ${approve_cmd[*]}"

    peer_with_retry "${approve_cmd[@]}"

    log_success "Chaincode approved for ${msp_id}"
}

approve_for_all_orgs() {
    log_step "Step 3: Approving chaincode for all organizations..."

    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r org_name msp_id peer_host peer_port <<< "${org_config}"
        approve_chaincode "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"
    done

    log_success "Chaincode approved by all organizations"
}

# Check commit readiness
check_commit_readiness() {
    log_info "Checking commit readiness..."

    # Use first org for query
    IFS=':' read -r org_name msp_id peer_host peer_port <<< "${ORG_CONFIGS[0]}"
    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    local check_cmd=(
        peer lifecycle chaincode checkcommitreadiness
        --channelID "${CHANNEL_NAME}"
        --name "${CC_NAME}"
        --version "${CC_VERSION}"
        --sequence "${CC_SEQUENCE}"
        --output json
    )

    if [[ -n "${COLLECTIONS_CONFIG}" ]] && [[ -f "${COLLECTIONS_CONFIG}" ]]; then
        check_cmd+=(--collections-config "${COLLECTIONS_CONFIG}")
    fi

    if [[ "${CC_INIT_REQUIRED}" == "true" ]]; then
        check_cmd+=(--init-required)
    fi

    local result
    result=$("${check_cmd[@]}" 2>&1)

    log_verbose "Commit readiness: ${result}"

    # Check if all orgs have approved
    local all_approved=true
    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r _ msp_id _ _ <<< "${org_config}"
        if ! echo "${result}" | grep -q "\"${msp_id}\": true"; then
            log_warn "${msp_id} has not approved"
            all_approved=false
        fi
    done

    if [[ "${all_approved}" == "false" ]]; then
        log_error "Not all organizations have approved the chaincode"
        return 1
    fi

    log_success "All organizations have approved - ready to commit"
}

# Step 4: Commit chaincode definition
commit_chaincode() {
    log_step "Step 4: Committing chaincode definition..."

    # Use first org for commit
    IFS=':' read -r org_name msp_id peer_host peer_port <<< "${ORG_CONFIGS[0]}"
    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    # Build peer connection args for all orgs
    local peer_conn_args=()
    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r o_name o_msp o_host o_port <<< "${org_config}"
        local o_domain
        o_domain=$(echo "${o_name}" | tr '[:upper:]' '[:lower:]')
        local tls_cert="${CRYPTO_DIR}/peerOrganizations/${o_domain}.tolling.network/peers/${o_host}/tls/ca.crt"
        peer_conn_args+=(--peerAddresses "${o_host}:${o_port}" --tlsRootCertFiles "${tls_cert}")
    done

    # Build commit command
    local commit_cmd=(
        peer lifecycle chaincode commit
        -o "${ORDERER_ADDRESS}"
        --channelID "${CHANNEL_NAME}"
        --name "${CC_NAME}"
        --version "${CC_VERSION}"
        --sequence "${CC_SEQUENCE}"
        --tls
        --cafile "${ORDERER_CA}"
    )

    # Add peer connection args
    commit_cmd+=("${peer_conn_args[@]}")

    # Add collections config if available
    if [[ -n "${COLLECTIONS_CONFIG}" ]] && [[ -f "${COLLECTIONS_CONFIG}" ]]; then
        commit_cmd+=(--collections-config "${COLLECTIONS_CONFIG}")
    fi

    # Add init required flag if set
    if [[ "${CC_INIT_REQUIRED}" == "true" ]]; then
        commit_cmd+=(--init-required)
    fi

    log_verbose "Commit command: ${commit_cmd[*]}"

    peer_with_retry "${commit_cmd[@]}"

    log_success "Chaincode definition committed to channel '${CHANNEL_NAME}'"
}

# Step 5: Verify deployment
verify_deployment() {
    log_step "Step 5: Verifying chaincode deployment..."

    # Use first org for query
    IFS=':' read -r org_name msp_id peer_host peer_port <<< "${ORG_CONFIGS[0]}"
    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    log_info "Querying committed chaincode..."

    local result
    result=$(peer lifecycle chaincode querycommitted \
        --channelID "${CHANNEL_NAME}" \
        --name "${CC_NAME}" \
        --output json 2>&1)

    log_verbose "Query result: ${result}"

    if echo "${result}" | grep -q "\"name\": \"${CC_NAME}\""; then
        log_success "Chaincode '${CC_NAME}' is committed on channel '${CHANNEL_NAME}'"

        # Extract details
        local version sequence
        version=$(echo "${result}" | grep -oP '"version": "\K[^"]+' | head -1 || echo "unknown")
        sequence=$(echo "${result}" | grep -oP '"sequence": \K[0-9]+' | head -1 || echo "unknown")

        log_info "  Version: ${version}"
        log_info "  Sequence: ${sequence}"
    else
        log_error "Chaincode verification failed"
        log_error "Result: ${result}"
        exit 1
    fi
}

# ==============================================================================
# Summary
# ==============================================================================

print_summary() {
    echo ""
    echo "=============================================================================="
    echo "                    Chaincode Deployment Complete"
    echo "=============================================================================="
    echo ""
    echo "Chaincode Details:"
    echo "  Name:       ${CC_NAME}"
    echo "  Version:    ${CC_VERSION}"
    echo "  Sequence:   ${CC_SEQUENCE}"
    echo "  Language:   ${CC_LANG}"
    echo "  Channel:    ${CHANNEL_NAME}"
    echo ""
    echo "Package: ${CC_PACKAGE}"
    echo ""
    if [[ -n "${COLLECTIONS_CONFIG}" ]]; then
        echo "Private Data Collections: ${COLLECTIONS_CONFIG}"
        echo ""
    fi
    echo "Deployed to peers:"
    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r _ msp_id peer_host peer_port <<< "${org_config}"
        echo "  - ${peer_host}:${peer_port} (${msp_id})"
    done
    echo ""
    echo "Test the deployment:"
    echo "  peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{\"function\":\"GetMetadata\",\"Args\":[]}'"
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
            -n|--name)
                CC_NAME="$2"
                shift 2
                ;;
            -v|--version)
                CC_VERSION="$2"
                shift 2
                ;;
            -s|--sequence)
                CC_SEQUENCE="$2"
                shift 2
                ;;
            -c|--channel)
                CHANNEL_NAME="$2"
                shift 2
                ;;
            -p|--path)
                CC_SRC_PATH="$2"
                shift 2
                ;;
            -l|--lang)
                CC_LANG="$2"
                shift 2
                ;;
            --init-required)
                CC_INIT_REQUIRED="true"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage >&2
                exit 1
                ;;
        esac
    done

    # Update package path based on name/version
    CC_PACKAGE="${PACKAGE_DIR}/${CC_NAME}_${CC_VERSION}.tar.gz"

    echo ""
    log_info "=============================================="
    log_info "Tolling.Network - Chaincode Deployment"
    log_info "=============================================="
    log_info "Chaincode: ${CC_NAME} v${CC_VERSION} (seq ${CC_SEQUENCE})"
    log_info "Channel: ${CHANNEL_NAME}"
    log_info "Source: ${CC_SRC_PATH}"
    echo ""

    # Set FABRIC_CFG_PATH
    export FABRIC_CFG_PATH="${NETWORK_CONFIG_DIR}"

    # Run deployment steps
    check_prerequisites
    package_chaincode
    install_on_all_peers
    approve_for_all_orgs
    check_commit_readiness
    commit_chaincode
    verify_deployment

    print_summary
}

main "$@"
