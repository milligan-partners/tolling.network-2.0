#!/bin/bash
#
# upgrade-chaincode.sh
#
# Upgrades chaincode on the Tolling.Network Hyperledger Fabric 2.5.x network.
#
# This script:
# - Queries the current deployed chaincode version and sequence
# - Auto-increments the sequence number
# - Supports code upgrades and policy-only upgrades
# - Provides dry-run mode to preview changes
# - Includes pre-upgrade validation
#
# Prerequisites:
# - Network must be running
# - Chaincode must already be deployed (use deploy-chaincode.sh for initial deployment)
# - peer CLI tool in PATH
#
# Usage:
#   ./upgrade-chaincode.sh [OPTIONS]
#
# Options:
#   -h, --help              Show this help message
#   -n, --name NAME         Chaincode name (default: niop)
#   -v, --version VERSION   New chaincode version (required for code upgrades)
#   -c, --channel NAME      Channel name (default: tolling)
#   -p, --path PATH         Chaincode source path (default: chaincode/niop)
#   --policy-only           Only update endorsement policy (no code change)
#   --dry-run               Preview upgrade without executing
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
CC_VERSION="${CC_VERSION:-}"
CHANNEL_NAME="${CHANNEL_NAME:-tolling}"
CC_SRC_PATH="${CC_SRC_PATH:-}"
CC_LANG="${CC_LANG:-golang}"
POLICY_ONLY="${POLICY_ONLY:-false}"
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
COMMIT_TIMEOUT="${COMMIT_TIMEOUT:-120}"
RETRY_DELAY="${RETRY_DELAY:-5}"
MAX_RETRIES="${MAX_RETRIES:-5}"

# Organization configurations (indexed arrays for bash 3.x compatibility)
ORG_CONFIGS=(
    "Org1:Org1MSP:peer0.org1.tolling.network:7051"
    "Org2:Org2MSP:peer0.org2.tolling.network:8051"
    "Org3:Org3MSP:peer0.org3.tolling.network:9051"
    "Org4:Org4MSP:peer0.org4.tolling.network:10051"
)

# Current chaincode state (populated by get_current_chaincode_info)
CURRENT_VERSION=""
CURRENT_SEQUENCE=""
NEW_SEQUENCE=""

# Track package IDs per org (indexed array, matches ORG_CONFIGS order)
PACKAGE_IDS=()

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

Upgrade chaincode on the Tolling.Network using Fabric 2.x lifecycle.

Options:
  -h, --help              Show this help message
  -n, --name NAME         Chaincode name (default: ${CC_NAME})
  -v, --version VERSION   New chaincode version (required for code upgrades)
  -c, --channel NAME      Channel name (default: ${CHANNEL_NAME})
  -p, --path PATH         Chaincode source path
  --policy-only           Only update endorsement policy (no code change)
  --dry-run               Preview upgrade without executing
  --force                 Skip confirmation prompts
  --verbose               Enable verbose output

Examples:
  # Upgrade chaincode with new code
  $(basename "$0") -n niop -v 1.1 -p chaincode/niop

  # Upgrade endorsement policy only (no code change)
  $(basename "$0") -n niop --policy-only

  # Preview upgrade without executing
  $(basename "$0") -n niop -v 1.1 --dry-run

  # Force upgrade without confirmation
  $(basename "$0") -n niop -v 1.1 --force

Notes:
  - The sequence number is automatically incremented
  - For code upgrades, specify --version and --path
  - For policy-only upgrades, use --policy-only (no repackaging)
  - State data persists automatically through upgrades

Prerequisites:
  - Network running (docker-compose up)
  - Chaincode already deployed (use deploy-chaincode.sh for initial deployment)
EOF
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
        log_error "Use deploy-chaincode.sh for initial deployment"
        exit 1
    fi
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

    # For code upgrades, check source path
    if [[ "${POLICY_ONLY}" != "true" ]]; then
        if [[ -z "${CC_SRC_PATH}" ]]; then
            CC_SRC_PATH="${PROJECT_ROOT}/chaincode/${CC_NAME}"
        fi

        if [[ ! -d "${CC_SRC_PATH}" ]]; then
            log_error "Chaincode source not found: ${CC_SRC_PATH}"
            missing+=("chaincode source")
        fi

        if [[ -z "${CC_VERSION}" ]]; then
            log_error "New version required for code upgrade (use -v/--version)"
            missing+=("version")
        fi

        # Check for go.mod in golang chaincode
        if [[ "${CC_LANG}" == "golang" ]] && [[ ! -f "${CC_SRC_PATH}/go.mod" ]]; then
            log_error "go.mod not found in chaincode source"
            missing+=("go.mod")
        fi
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing prerequisites: ${missing[*]}"
        exit 1
    fi

    log_success "Prerequisites satisfied"
}

# ==============================================================================
# Upgrade Operations
# ==============================================================================

# Display upgrade plan
show_upgrade_plan() {
    echo ""
    echo "=============================================================================="
    echo "                        Chaincode Upgrade Plan"
    echo "=============================================================================="
    echo ""
    echo "Chaincode: ${CC_NAME}"
    echo ""
    echo "Current State:"
    echo "  Version:  ${CURRENT_VERSION}"
    echo "  Sequence: ${CURRENT_SEQUENCE}"
    echo ""
    echo "After Upgrade:"
    if [[ "${POLICY_ONLY}" == "true" ]]; then
        echo "  Version:  ${CURRENT_VERSION} (unchanged)"
    else
        echo "  Version:  ${CC_VERSION}"
    fi
    echo "  Sequence: ${NEW_SEQUENCE}"
    echo ""
    echo "Upgrade Type: $(if [[ "${POLICY_ONLY}" == "true" ]]; then echo "Policy-only (no code change)"; else echo "Code upgrade"; fi)"
    echo "Channel: ${CHANNEL_NAME}"
    echo ""
    if [[ "${POLICY_ONLY}" != "true" ]]; then
        echo "Source: ${CC_SRC_PATH}"
        echo ""
    fi
    echo "Organizations to update:"
    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r _ msp_id peer_host peer_port <<< "${org_config}"
        echo "  - ${peer_host}:${peer_port} (${msp_id})"
    done
    echo ""
    echo "=============================================================================="
    echo ""
}

# Confirm upgrade with user
confirm_upgrade() {
    if [[ "${FORCE}" == "true" ]]; then
        return 0
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_dry_run "Dry run mode - no changes will be made"
        return 1
    fi

    echo -e "${YELLOW}WARNING: This will upgrade the chaincode on all peers.${NC}"
    echo -e "${YELLOW}State data will be preserved, but ensure you have backups.${NC}"
    echo ""
    read -p "Proceed with upgrade? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Upgrade cancelled by user"
        exit 0
    fi
}

# Package chaincode (for code upgrades)
package_chaincode() {
    if [[ "${POLICY_ONLY}" == "true" ]]; then
        log_info "Policy-only upgrade - skipping packaging"
        return 0
    fi

    log_step "Packaging chaincode..."

    mkdir -p "${PACKAGE_DIR}"

    local cc_package="${PACKAGE_DIR}/${CC_NAME}_${CC_VERSION}.tar.gz"

    # Check if package already exists
    if [[ -f "${cc_package}" ]]; then
        log_warn "Package already exists: ${cc_package}"
        log_warn "Using existing package (delete to force rebuild)"
    else
        log_info "Creating package: ${cc_package}"

        # Vendor dependencies for golang
        if [[ "${CC_LANG}" == "golang" ]]; then
            log_verbose "Vendoring Go dependencies..."
            (cd "${CC_SRC_PATH}" && GO111MODULE=on go mod vendor 2>/dev/null || true)
        fi

        peer lifecycle chaincode package "${cc_package}" \
            --path "${CC_SRC_PATH}" \
            --lang "${CC_LANG}" \
            --label "${CC_NAME}_${CC_VERSION}"

        local size
        size=$(du -h "${cc_package}" | cut -f1)
        log_success "Chaincode packaged: ${cc_package} (${size})"
    fi

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

    if [[ "${POLICY_ONLY}" == "true" ]]; then
        # For policy-only, get existing package ID
        set_org_env "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}"
        local query_result
        query_result=$(peer lifecycle chaincode queryinstalled 2>&1)
        local package_id
        # Use sed instead of grep -P for macOS compatibility
        package_id=$(echo "${query_result}" | grep "${CC_NAME}_${CURRENT_VERSION}" | sed -n 's/.*Package ID: \([^,]*\).*/\1/p' | head -1)

        if [[ -z "${package_id}" ]]; then
            log_error "Could not find installed package for ${CC_NAME}_${CURRENT_VERSION}"
            exit 1
        fi

        PACKAGE_IDS[${org_index}]="${package_id}"
        log_verbose "Using existing package ID for ${msp_id}: ${package_id}"
        return 0
    fi

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
        package_id=$(echo "${query_result}" | grep "${CC_NAME}_${CC_VERSION}" | sed -n 's/.*Package ID: \([^,]*\).*/\1/p' | head -1)
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
    local version="${CC_VERSION}"

    if [[ "${POLICY_ONLY}" == "true" ]]; then
        version="${CURRENT_VERSION}"
    fi

    # Build approve command
    local approve_cmd=(
        peer lifecycle chaincode approveformyorg
        -o "${ORDERER_ADDRESS}"
        --channelID "${CHANNEL_NAME}"
        --name "${CC_NAME}"
        --version "${version}"
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

    local version="${CC_VERSION}"
    if [[ "${POLICY_ONLY}" == "true" ]]; then
        version="${CURRENT_VERSION}"
    fi

    local check_cmd=(
        peer lifecycle chaincode checkcommitreadiness
        --channelID "${CHANNEL_NAME}"
        --name "${CC_NAME}"
        --version "${version}"
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

    local version="${CC_VERSION}"
    if [[ "${POLICY_ONLY}" == "true" ]]; then
        version="${CURRENT_VERSION}"
    fi

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
        --version "${version}"
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

# Verify upgrade
verify_upgrade() {
    log_step "Verifying chaincode upgrade..."

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

    if [[ "${new_sequence}" == "${NEW_SEQUENCE}" ]]; then
        log_success "Upgrade verified successfully!"
        log_info "  Version:  ${new_version}"
        log_info "  Sequence: ${new_sequence}"
    else
        log_error "Upgrade verification failed"
        log_error "Expected sequence ${NEW_SEQUENCE}, got ${new_sequence}"
        exit 1
    fi
}

# Print summary and rollback instructions
print_summary() {
    local version="${CC_VERSION}"
    if [[ "${POLICY_ONLY}" == "true" ]]; then
        version="${CURRENT_VERSION}"
    fi

    echo ""
    echo "=============================================================================="
    echo "                      Chaincode Upgrade Complete"
    echo "=============================================================================="
    echo ""
    echo "Upgraded: ${CC_NAME}"
    echo "  Previous: v${CURRENT_VERSION} (seq ${CURRENT_SEQUENCE})"
    echo "  Current:  v${version} (seq ${NEW_SEQUENCE})"
    echo ""
    echo "Rollback Instructions:"
    echo "  If you need to roll back to the previous version:"
    echo ""
    echo "  ./scripts/rollback-chaincode.sh -n ${CC_NAME} -v ${CURRENT_VERSION}"
    echo ""
    echo "  Or manually:"
    echo "  1. Checkout previous code from Git"
    echo "  2. Run: ./scripts/upgrade-chaincode.sh -n ${CC_NAME} -v ${CURRENT_VERSION} -p <path>"
    echo "     (This will use sequence $((NEW_SEQUENCE + 1)))"
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
            -c|--channel)
                CHANNEL_NAME="$2"
                shift 2
                ;;
            -p|--path)
                CC_SRC_PATH="$2"
                shift 2
                ;;
            --policy-only)
                POLICY_ONLY="true"
                shift
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
    log_info "Tolling.Network - Chaincode Upgrade"
    log_info "=============================================="
    echo ""

    # Set FABRIC_CFG_PATH
    export FABRIC_CFG_PATH="${NETWORK_CONFIG_DIR}"

    # Get current chaincode info
    get_current_chaincode_info

    # Check prerequisites
    check_prerequisites

    # Show upgrade plan
    show_upgrade_plan

    # Confirm with user (or dry-run)
    if ! confirm_upgrade; then
        exit 0
    fi

    # Execute upgrade
    package_chaincode
    install_on_all_peers
    approve_for_all_orgs
    check_commit_readiness
    commit_chaincode
    verify_upgrade

    print_summary
}

main "$@"
