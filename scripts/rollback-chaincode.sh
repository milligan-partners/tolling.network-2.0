#!/bin/bash
#
# rollback-chaincode.sh
#
# Rolls back chaincode to a previous version on the Tolling.Network.
#
# In Hyperledger Fabric 2.x, rollback is achieved by deploying the previous
# code version with a new (incremented) sequence number. This is essentially
# an upgrade to the old code.
#
# This script:
# - Queries the current deployed chaincode version and sequence
# - Checks out the specified version from Git (or uses specified path)
# - Deploys the old code with a new sequence number
#
# Prerequisites:
# - Network must be running
# - Chaincode must be currently deployed
# - Git history available (for version checkout) or source path specified
#
# Usage:
#   ./rollback-chaincode.sh [OPTIONS]
#
# Options:
#   -h, --help              Show this help message
#   -n, --name NAME         Chaincode name (default: niop)
#   -v, --version VERSION   Target version to roll back to (required)
#   -t, --tag TAG           Git tag to checkout (alternative to path)
#   -p, --path PATH         Path to previous chaincode source
#   -c, --channel NAME      Channel name (default: tolling)
#   --dry-run               Preview rollback without executing
#   --force                 Skip confirmation prompts
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
TARGET_VERSION="${TARGET_VERSION:-}"
GIT_TAG="${GIT_TAG:-}"
CC_SRC_PATH="${CC_SRC_PATH:-}"
CHANNEL_NAME="${CHANNEL_NAME:-tolling}"
CC_LANG="${CC_LANG:-golang}"
DRY_RUN="${DRY_RUN:-false}"
FORCE="${FORCE:-false}"
VERBOSE="${VERBOSE:-false}"

# Package output directory
PACKAGE_DIR="${PROJECT_ROOT}/chaincode/packages"

# Network configuration
ORDERER_HOST="orderer1.orderer.tolling.network"
ORDERER_PORT="7050"
ORDERER_ADDRESS="${ORDERER_HOST}:${ORDERER_PORT}"
ORDERER_CA="${CRYPTO_DIR}/ordererOrganizations/orderer.tolling.network/orderers/orderer1.orderer.tolling.network/msp/tlscacerts/tlsca.orderer.tolling.network-cert.pem"

# Timeout for operations
RETRY_DELAY="${RETRY_DELAY:-5}"
MAX_RETRIES="${MAX_RETRIES:-5}"

# Organization configurations
# Organization configurations (indexed arrays for bash 3.x compatibility)
ORG_CONFIGS=(
    "Org1:Org1MSP:peer0.org1.tolling.network:7051"
    "Org2:Org2MSP:peer0.org2.tolling.network:8051"
    "Org3:Org3MSP:peer0.org3.tolling.network:9051"
    "Org4:Org4MSP:peer0.org4.tolling.network:10051"
)

# Current chaincode state
CURRENT_VERSION=""
CURRENT_SEQUENCE=""
NEW_SEQUENCE=""

# Track package IDs per org (indexed array, matches ORG_CONFIGS order)
PACKAGE_IDS=()

# Temporary directory for git checkout
TEMP_SRC_DIR=""

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

log_dry_run() {
    echo -e "${YELLOW}[DRY-RUN]${NC} $*"
}

# ==============================================================================
# Usage
# ==============================================================================

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Roll back chaincode to a previous version on the Tolling.Network.

In Fabric 2.x, rollback is achieved by deploying the previous code with a new
sequence number. State data is preserved.

Options:
  -h, --help              Show this help message
  -n, --name NAME         Chaincode name (default: ${CC_NAME})
  -v, --version VERSION   Target version to roll back to (required)
  -t, --tag TAG           Git tag to checkout (e.g., v1.0.0, chaincode-1.0)
  -p, --path PATH         Path to previous chaincode source
  -c, --channel NAME      Channel name (default: ${CHANNEL_NAME})
  --dry-run               Preview rollback without executing
  --force                 Skip confirmation prompts
  --verbose               Enable verbose output

Examples:
  # Roll back using a git tag
  $(basename "$0") -n niop -v 1.0 -t v1.0.0

  # Roll back using a specific source path
  $(basename "$0") -n niop -v 1.0 -p /path/to/old/chaincode

  # Preview rollback without executing
  $(basename "$0") -n niop -v 1.0 -t v1.0.0 --dry-run

Notes:
  - Either --tag or --path must be specified
  - The rollback creates a new sequence number (not a true revert)
  - State data persists through the rollback
  - Consider this a "forward-only" system - you're deploying old code, not undoing

Prerequisites:
  - Network running (docker-compose up)
  - Chaincode currently deployed
  - Git history available (for --tag) or source path (for --path)
EOF
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# Cleanup function for temporary directory
cleanup() {
    if [[ -n "${TEMP_SRC_DIR}" ]] && [[ -d "${TEMP_SRC_DIR}" ]]; then
        log_verbose "Cleaning up temporary directory: ${TEMP_SRC_DIR}"
        rm -rf "${TEMP_SRC_DIR}"
    fi
}

trap cleanup EXIT

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
# Chaincode Status Functions
# ==============================================================================

# Get current chaincode information from the channel
get_current_chaincode_info() {
    log_info "Querying current chaincode status..."

    # Use first org for query
    IFS=':' read -r org_name msp_id peer_host peer_port <<< "${ORG_CONFIGS[0]}"
    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    local result
    result=$(peer lifecycle chaincode querycommitted \
        --channelID "${CHANNEL_NAME}" \
        --name "${CC_NAME}" \
        --output json 2>&1) || true

    if echo "${result}" | grep -q "\"name\": \"${CC_NAME}\""; then
        # Use sed for macOS compatibility (no grep -P)
        CURRENT_VERSION=$(echo "${result}" | sed -n 's/.*"version": "\([^"]*\)".*/\1/p' | head -1)
        CURRENT_SEQUENCE=$(echo "${result}" | sed -n 's/.*"sequence": \([0-9]*\).*/\1/p' | head -1)
        NEW_SEQUENCE=$((CURRENT_SEQUENCE + 1))

        log_success "Found deployed chaincode:"
        log_info "  Name:     ${CC_NAME}"
        log_info "  Version:  ${CURRENT_VERSION}"
        log_info "  Sequence: ${CURRENT_SEQUENCE}"
        log_info "  New Sequence will be: ${NEW_SEQUENCE}"
        return 0
    else
        log_error "Chaincode '${CC_NAME}' is not deployed on channel '${CHANNEL_NAME}'"
        exit 1
    fi
}

# ==============================================================================
# Git Operations
# ==============================================================================

# Checkout code from git tag to temporary directory
checkout_from_git() {
    log_step "Checking out code from git tag: ${GIT_TAG}..."

    # Verify tag exists
    if ! git -C "${PROJECT_ROOT}" rev-parse "${GIT_TAG}" &>/dev/null; then
        log_error "Git tag '${GIT_TAG}' not found"
        log_info "Available tags:"
        git -C "${PROJECT_ROOT}" tag -l | head -20
        exit 1
    fi

    # Create temporary directory
    TEMP_SRC_DIR=$(mktemp -d)
    log_verbose "Created temporary directory: ${TEMP_SRC_DIR}"

    # Clone the repo at the specified tag
    log_info "Cloning repository at tag ${GIT_TAG}..."
    git clone --depth 1 --branch "${GIT_TAG}" "${PROJECT_ROOT}" "${TEMP_SRC_DIR}/repo" 2>/dev/null

    # Set the chaincode source path
    CC_SRC_PATH="${TEMP_SRC_DIR}/repo/chaincode/${CC_NAME}"

    if [[ ! -d "${CC_SRC_PATH}" ]]; then
        log_error "Chaincode directory not found in tag: ${CC_SRC_PATH}"
        exit 1
    fi

    log_success "Code checked out to: ${CC_SRC_PATH}"
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
    fi

    # Check for crypto material
    if [[ ! -d "${CRYPTO_DIR}" ]]; then
        log_error "Crypto material not found: ${CRYPTO_DIR}"
        missing+=("crypto-config")
    fi

    # Check that target version is specified
    if [[ -z "${TARGET_VERSION}" ]]; then
        log_error "Target version required (use -v/--version)"
        missing+=("version")
    fi

    # Check that either tag or path is specified
    if [[ -z "${GIT_TAG}" ]] && [[ -z "${CC_SRC_PATH}" ]]; then
        log_error "Either --tag or --path must be specified"
        missing+=("source")
    fi

    # Check for git if using tag
    if [[ -n "${GIT_TAG}" ]]; then
        if ! command -v git &> /dev/null; then
            log_error "git not found in PATH (required for --tag)"
            missing+=("git")
        fi
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing prerequisites: ${missing[*]}"
        exit 1
    fi

    log_success "Prerequisites satisfied"
}

# ==============================================================================
# Rollback Operations
# ==============================================================================

# Display rollback plan
show_rollback_plan() {
    echo ""
    echo "=============================================================================="
    echo "                        Chaincode Rollback Plan"
    echo "=============================================================================="
    echo ""
    echo -e "${RED}WARNING: This will roll back the chaincode to a previous version.${NC}"
    echo ""
    echo "Chaincode: ${CC_NAME}"
    echo ""
    echo "Current State:"
    echo "  Version:  ${CURRENT_VERSION}"
    echo "  Sequence: ${CURRENT_SEQUENCE}"
    echo ""
    echo "After Rollback:"
    echo "  Version:  ${TARGET_VERSION}"
    echo "  Sequence: ${NEW_SEQUENCE}"
    echo ""
    echo "Source:"
    if [[ -n "${GIT_TAG}" ]]; then
        echo "  Git Tag: ${GIT_TAG}"
    fi
    echo "  Path: ${CC_SRC_PATH}"
    echo ""
    echo "Channel: ${CHANNEL_NAME}"
    echo ""
    echo "Organizations to update:"
    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r _ msp_id peer_host peer_port <<< "${org_config}"
        echo "  - ${peer_host}:${peer_port} (${msp_id})"
    done
    echo ""
    echo "=============================================================================="
    echo ""
}

# Confirm rollback with user
confirm_rollback() {
    if [[ "${FORCE}" == "true" ]]; then
        return 0
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_dry_run "Dry run mode - no changes will be made"
        return 1
    fi

    echo -e "${RED}WARNING: You are about to roll back chaincode to a previous version.${NC}"
    echo -e "${YELLOW}This is a forward-only operation - a new sequence number will be used.${NC}"
    echo -e "${YELLOW}State data will be preserved.${NC}"
    echo ""
    read -p "Are you sure you want to proceed? Type 'ROLLBACK' to confirm: " -r
    echo ""
    if [[ "${REPLY}" != "ROLLBACK" ]]; then
        log_info "Rollback cancelled by user"
        exit 0
    fi
}

# Package chaincode
package_chaincode() {
    log_step "Packaging chaincode..."

    mkdir -p "${PACKAGE_DIR}"

    local cc_package="${PACKAGE_DIR}/${CC_NAME}_${TARGET_VERSION}_rollback.tar.gz"

    # Always create fresh package for rollback
    if [[ -f "${cc_package}" ]]; then
        log_warn "Removing existing rollback package..."
        rm -f "${cc_package}"
    fi

    log_info "Creating package: ${cc_package}"

    # Vendor dependencies for golang
    if [[ "${CC_LANG}" == "golang" ]]; then
        log_verbose "Vendoring Go dependencies..."
        (cd "${CC_SRC_PATH}" && GO111MODULE=on go mod vendor 2>/dev/null || true)
    fi

    peer lifecycle chaincode package "${cc_package}" \
        --path "${CC_SRC_PATH}" \
        --lang "${CC_LANG}" \
        --label "${CC_NAME}_${TARGET_VERSION}"

    local size
    size=$(du -h "${cc_package}" | cut -f1)
    log_success "Chaincode packaged: ${cc_package} (${size})"

    CC_PACKAGE="${cc_package}"
}

# Install chaincode on a peer
# Args: org_index org_name msp_id peer_host peer_port
install_chaincode() {
    local org_index="$1"
    local org_name="$2"
    local msp_id="$3"
    local peer_host="$4"
    local peer_port="$5"

    log_info "Installing chaincode on ${peer_host}..."

    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    local result
    result=$(peer_with_retry lifecycle chaincode install "${CC_PACKAGE}")

    # Extract package ID (use sed for macOS compatibility)
    local package_id
    package_id=$(echo "${result}" | sed -n 's/.*Chaincode code package identifier: \([^ ]*\).*/\1/p' | head -1)
    if [[ -z "${package_id}" ]]; then
        package_id=$(echo "${result}" | sed -n 's/.*Package ID: \([^ ]*\).*/\1/p' | head -1)
    fi

    if [[ -z "${package_id}" ]]; then
        local query_result
        query_result=$(peer lifecycle chaincode queryinstalled 2>&1)
        package_id=$(echo "${query_result}" | grep "${CC_NAME}_${TARGET_VERSION}" | sed -n 's/.*Package ID: \([^,]*\).*/\1/p' | head -1)
    fi

    if [[ -z "${package_id}" ]]; then
        log_error "Failed to get package ID for ${msp_id}"
        exit 1
    fi

    PACKAGE_IDS[${org_index}]="${package_id}"
    log_success "Chaincode installed on ${peer_host}"
}

install_on_all_peers() {
    log_step "Installing chaincode on all peers..."

    local org_index=0
    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r org_name msp_id peer_host peer_port <<< "${org_config}"
        install_chaincode "${org_index}" "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"
        org_index=$((org_index + 1))
    done

    log_success "Chaincode installed on all peers"
}

# Approve chaincode for an organization
# Args: org_index org_name msp_id peer_host peer_port
approve_chaincode() {
    local org_index="$1"
    local org_name="$2"
    local msp_id="$3"
    local peer_host="$4"
    local peer_port="$5"

    log_info "Approving chaincode for ${msp_id}..."

    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    local package_id="${PACKAGE_IDS[${org_index}]}"

    # Build approve command
    local approve_cmd=(
        peer lifecycle chaincode approveformyorg
        -o "${ORDERER_ADDRESS}"
        --channelID "${CHANNEL_NAME}"
        --name "${CC_NAME}"
        --version "${TARGET_VERSION}"
        --package-id "${package_id}"
        --sequence "${NEW_SEQUENCE}"
        --tls
        --cafile "${ORDERER_CA}"
    )

    # Add collections config if available
    if [[ -n "${COLLECTIONS_CONFIG}" ]] && [[ -f "${COLLECTIONS_CONFIG}" ]]; then
        approve_cmd+=(--collections-config "${COLLECTIONS_CONFIG}")
    fi

    peer_with_retry "${approve_cmd[@]}"

    log_success "Chaincode approved for ${msp_id}"
}

approve_for_all_orgs() {
    log_step "Approving chaincode for all organizations..."

    local org_index=0
    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r org_name msp_id peer_host peer_port <<< "${org_config}"
        approve_chaincode "${org_index}" "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"
        org_index=$((org_index + 1))
    done

    log_success "Chaincode approved by all organizations"
}

# Check commit readiness
check_commit_readiness() {
    log_info "Checking commit readiness..."

    IFS=':' read -r org_name msp_id peer_host peer_port <<< "${ORG_CONFIGS[0]}"
    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    local check_cmd=(
        peer lifecycle chaincode checkcommitreadiness
        --channelID "${CHANNEL_NAME}"
        --name "${CC_NAME}"
        --version "${TARGET_VERSION}"
        --sequence "${NEW_SEQUENCE}"
        --output json
    )

    if [[ -n "${COLLECTIONS_CONFIG}" ]] && [[ -f "${COLLECTIONS_CONFIG}" ]]; then
        check_cmd+=(--collections-config "${COLLECTIONS_CONFIG}")
    fi

    local result
    result=$("${check_cmd[@]}" 2>&1)

    log_verbose "Commit readiness: ${result}"

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

# Commit chaincode definition
commit_chaincode() {
    log_step "Committing chaincode definition..."

    IFS=':' read -r org_name msp_id peer_host peer_port <<< "${ORG_CONFIGS[0]}"
    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    # Build peer connection args
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
        --version "${TARGET_VERSION}"
        --sequence "${NEW_SEQUENCE}"
        --tls
        --cafile "${ORDERER_CA}"
    )

    commit_cmd+=("${peer_conn_args[@]}")

    if [[ -n "${COLLECTIONS_CONFIG}" ]] && [[ -f "${COLLECTIONS_CONFIG}" ]]; then
        commit_cmd+=(--collections-config "${COLLECTIONS_CONFIG}")
    fi

    peer_with_retry "${commit_cmd[@]}"

    log_success "Chaincode definition committed"
}

# Verify rollback
verify_rollback() {
    log_step "Verifying chaincode rollback..."

    IFS=':' read -r org_name msp_id peer_host peer_port <<< "${ORG_CONFIGS[0]}"
    set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"

    local result
    result=$(peer lifecycle chaincode querycommitted \
        --channelID "${CHANNEL_NAME}" \
        --name "${CC_NAME}" \
        --output json 2>&1)

    local new_version new_sequence
    # Use sed for macOS compatibility (no grep -P)
    new_version=$(echo "${result}" | sed -n 's/.*"version": "\([^"]*\)".*/\1/p' | head -1)
    new_sequence=$(echo "${result}" | sed -n 's/.*"sequence": \([0-9]*\).*/\1/p' | head -1)

    if [[ "${new_sequence}" == "${NEW_SEQUENCE}" ]] && [[ "${new_version}" == "${TARGET_VERSION}" ]]; then
        log_success "Rollback verified successfully!"
        log_info "  Version:  ${new_version}"
        log_info "  Sequence: ${new_sequence}"
    else
        log_error "Rollback verification failed"
        log_error "Expected version ${TARGET_VERSION} (seq ${NEW_SEQUENCE})"
        log_error "Got version ${new_version} (seq ${new_sequence})"
        exit 1
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "=============================================================================="
    echo "                      Chaincode Rollback Complete"
    echo "=============================================================================="
    echo ""
    echo "Rolled back: ${CC_NAME}"
    echo "  From:     v${CURRENT_VERSION} (seq ${CURRENT_SEQUENCE})"
    echo "  To:       v${TARGET_VERSION} (seq ${NEW_SEQUENCE})"
    echo ""
    echo "Important Notes:"
    echo "  - This was a forward-only rollback (new sequence number)"
    echo "  - State data has been preserved"
    echo "  - To re-upgrade, increment the sequence again"
    echo ""
    echo "To upgrade again later:"
    echo "  ./scripts/upgrade-chaincode.sh -n ${CC_NAME} -v <new-version> -p <path>"
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
                TARGET_VERSION="$2"
                shift 2
                ;;
            -t|--tag)
                GIT_TAG="$2"
                shift 2
                ;;
            -p|--path)
                CC_SRC_PATH="$2"
                shift 2
                ;;
            -c|--channel)
                CHANNEL_NAME="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --force)
                FORCE="true"
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

    echo ""
    log_info "=============================================="
    log_info "Tolling.Network - Chaincode Rollback"
    log_info "=============================================="
    echo ""

    # Set FABRIC_CFG_PATH
    export FABRIC_CFG_PATH="${NETWORK_CONFIG_DIR}"

    # Check prerequisites first
    check_prerequisites

    # Get current chaincode info
    get_current_chaincode_info

    # Check if rolling back to current version
    if [[ "${TARGET_VERSION}" == "${CURRENT_VERSION}" ]]; then
        log_warn "Target version ${TARGET_VERSION} is the same as current version"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi

    # Checkout code if using git tag
    if [[ -n "${GIT_TAG}" ]]; then
        checkout_from_git
    fi

    # Validate source path exists
    if [[ ! -d "${CC_SRC_PATH}" ]]; then
        log_error "Chaincode source not found: ${CC_SRC_PATH}"
        exit 1
    fi

    # Check for go.mod
    if [[ "${CC_LANG}" == "golang" ]] && [[ ! -f "${CC_SRC_PATH}/go.mod" ]]; then
        log_error "go.mod not found in chaincode source: ${CC_SRC_PATH}"
        exit 1
    fi

    # Show rollback plan
    show_rollback_plan

    # Confirm with user (or dry-run)
    if ! confirm_rollback; then
        exit 0
    fi

    # Execute rollback (same steps as upgrade)
    package_chaincode
    install_on_all_peers
    approve_for_all_orgs
    check_commit_readiness
    commit_chaincode
    verify_rollback

    print_summary
}

main "$@"
