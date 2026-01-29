#!/bin/bash
#
# deploy-ccaas.sh
#
# Deploys chaincode to the Tolling.Network using Chaincode as a Service (ccaas).
#
# This script:
# - Builds the chaincode Docker image
# - Creates the ccaas package (connection.json + metadata.json)
# - Installs the package on all peers
# - Starts the chaincode container with the package ID
# - Approves and commits the chaincode definition
#
# With ccaas, the chaincode runs as an external gRPC server that peers connect to,
# rather than having peers launch chaincode containers via Docker socket.
#
# Prerequisites:
# - Network must be running (docker compose up)
# - Channel must be created and all peers joined
# - Docker must be available for building the chaincode image
#
# Usage:
#   ./deploy-ccaas.sh [OPTIONS]
#
# Options:
#   -h, --help              Show this help message
#   -n, --name NAME         Chaincode name (default: niop)
#   -v, --version VERSION   Chaincode version (default: 1.0)
#   -s, --sequence SEQ      Chaincode sequence (default: 1)
#   -c, --channel NAME      Channel name (default: tolling)
#   --skip-build            Skip building the Docker image
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
CHAINCODE_DIR="${PROJECT_ROOT}/chaincode/niop"
CCAAS_DIR="${CHAINCODE_DIR}/ccaas"
NETWORK_CONFIG_DIR="${PROJECT_ROOT}/infrastructure/network-config"
CRYPTO_DIR="${NETWORK_CONFIG_DIR}/crypto-config"
COLLECTIONS_CONFIG="${PROJECT_ROOT}/network-config/collections/collections_config.json"
DOCKER_COMPOSE_DIR="${PROJECT_ROOT}/infrastructure/docker"

# Default values
CC_NAME="${CC_NAME:-niop}"
CC_VERSION="${CC_VERSION:-1.0}"
CC_SEQUENCE="${CC_SEQUENCE:-1}"
CHANNEL_NAME="${CHANNEL_NAME:-tolling}"
SKIP_BUILD="${SKIP_BUILD:-false}"
VERBOSE="${VERBOSE:-false}"

# Chaincode server address (as seen from within the Docker network)
CC_SERVER_ADDRESS="niop-chaincode:9999"
CC_SERVER_PORT="9999"

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

# Organization configurations
# Format: ORG_NAME:MSP_ID:PEER_HOST:PEER_PORT
declare -a ORG_CONFIGS=(
    "Org1:Org1MSP:peer0.org1.tolling.network:7051"
    "Org2:Org2MSP:peer0.org2.tolling.network:8051"
    "Org3:Org3MSP:peer0.org3.tolling.network:9051"
    "Org4:Org4MSP:peer0.org4.tolling.network:10051"
)

# Track the package ID (same for all orgs in ccaas since it's just metadata)
PACKAGE_ID=""

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

Deploy chaincode using Chaincode as a Service (ccaas).

Options:
  -h, --help              Show this help message
  -n, --name NAME         Chaincode name (default: ${CC_NAME})
  -v, --version VERSION   Chaincode version (default: ${CC_VERSION})
  -s, --sequence SEQ      Chaincode sequence (default: ${CC_SEQUENCE})
  -c, --channel NAME      Channel name (default: ${CHANNEL_NAME})
  --skip-build            Skip building the Docker image
  --verbose               Enable verbose output

Environment Variables:
  CC_NAME                 Chaincode name
  CC_VERSION              Chaincode version
  CC_SEQUENCE             Chaincode sequence number
  CHANNEL_NAME            Channel name

Examples:
  $(basename "$0")
  $(basename "$0") -n niop -v 1.0 -s 1
  $(basename "$0") --skip-build --verbose

Chaincode as a Service (ccaas) Lifecycle:
  1. Build chaincode Docker image
  2. Create ccaas package (connection.json + metadata.json)
  3. Install package on all peers
  4. Start chaincode container
  5. Approve for each organization
  6. Commit chaincode definition

Prerequisites:
  - Network running (docker compose up)
  - Channel created (./create-channel.sh)
  - Docker available for building image
EOF
}

# ==============================================================================
# Prerequisite Checks
# ==============================================================================

check_prerequisites() {
    log_info "Checking prerequisites..."
    local missing=()

    # Check for Docker
    if ! command -v docker &> /dev/null; then
        log_error "docker not found in PATH"
        missing+=("docker")
    else
        log_verbose "Found docker: $(command -v docker)"
    fi

    # Check for chaincode source
    if [[ ! -d "${CHAINCODE_DIR}" ]]; then
        log_error "Chaincode source not found: ${CHAINCODE_DIR}"
        missing+=("chaincode source")
    else
        log_verbose "Found chaincode source: ${CHAINCODE_DIR}"
    fi

    # Check for ccaas templates
    if [[ ! -f "${CCAAS_DIR}/connection.json" ]]; then
        log_error "connection.json template not found: ${CCAAS_DIR}/connection.json"
        missing+=("connection.json")
    fi

    if [[ ! -f "${CCAAS_DIR}/metadata.json" ]]; then
        log_error "metadata.json template not found: ${CCAAS_DIR}/metadata.json"
        missing+=("metadata.json")
    fi

    # Check for crypto material
    if [[ ! -d "${CRYPTO_DIR}" ]]; then
        log_error "Crypto material not found: ${CRYPTO_DIR}"
        missing+=("crypto-config")
    fi

    # Check network is running
    local docker_ps_output
    docker_ps_output=$(docker ps 2>/dev/null) || true
    if ! echo "${docker_ps_output}" | grep -q "peer0.org1.tolling.network"; then
        log_error "Network does not appear to be running (peer0.org1 not found)"
        missing+=("running network")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing prerequisites: ${missing[*]}"
        exit 1
    fi

    log_success "Prerequisites satisfied"
}

# ==============================================================================
# Docker Operations
# ==============================================================================

build_chaincode_image() {
    log_step "Step 1: Building chaincode Docker image..."

    if [[ "${SKIP_BUILD}" == "true" ]]; then
        log_warn "Skipping build (--skip-build specified)"
        return 0
    fi

    local image_name="${CC_NAME}-chaincode:${CC_VERSION}"
    local dockerfile="${CCAAS_DIR}/Dockerfile"

    log_info "Building image: ${image_name}"
    log_verbose "Dockerfile: ${dockerfile}"
    log_verbose "Context: ${PROJECT_ROOT}"

    docker build \
        -t "${image_name}" \
        -f "${dockerfile}" \
        "${PROJECT_ROOT}"

    log_success "Chaincode image built: ${image_name}"
}

# ==============================================================================
# Package Creation
# ==============================================================================

create_ccaas_package() {
    log_step "Step 2: Creating ccaas package..."

    mkdir -p "${PACKAGE_DIR}"

    local label="${CC_NAME}_${CC_VERSION}"
    local package_file="${PACKAGE_DIR}/${label}_ccaas.tar.gz"

    # Create temporary directory for package contents
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf ${tmp_dir}" EXIT

    # Create connection.json with the chaincode server address
    # The address must be resolvable from within the peer container
    cat > "${tmp_dir}/connection.json" <<EOF
{
  "address": "${CC_SERVER_ADDRESS}",
  "dial_timeout": "10s",
  "tls_required": false
}
EOF

    # Create metadata.json
    cat > "${tmp_dir}/metadata.json" <<EOF
{
  "type": "ccaas",
  "label": "${label}"
}
EOF

    log_verbose "connection.json:"
    log_verbose "$(cat "${tmp_dir}/connection.json")"
    log_verbose "metadata.json:"
    log_verbose "$(cat "${tmp_dir}/metadata.json")"

    # Create code.tar.gz (required structure for ccaas package)
    # For ccaas, code.tar.gz contains connection.json
    tar -czf "${tmp_dir}/code.tar.gz" -C "${tmp_dir}" connection.json

    # Create the final package
    tar -czf "${package_file}" -C "${tmp_dir}" code.tar.gz metadata.json

    if [[ ! -f "${package_file}" ]]; then
        log_error "Failed to create ccaas package"
        exit 1
    fi

    local size
    size=$(du -h "${package_file}" | cut -f1)
    log_success "ccaas package created: ${package_file} (${size})"

    echo "${package_file}"
}

# ==============================================================================
# Chaincode Lifecycle Operations
# ==============================================================================

# Execute command in CLI container
cli_exec() {
    docker exec cli "$@"
}

# Set environment for a specific org in CLI container
set_org_env_cli() {
    local org_name="$1"
    local msp_id="$2"
    local peer_host="$3"
    local peer_port="$4"

    local domain
    domain=$(echo "${org_name}" | tr '[:upper:]' '[:lower:]')

    cat <<EOF
export CORE_PEER_LOCALMSPID=${msp_id}
export CORE_PEER_ADDRESS=${peer_host}:${peer_port}
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${domain}.tolling.network/peers/${peer_host}/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${domain}.tolling.network/users/Admin@${domain}.tolling.network/msp
EOF
}

install_chaincode() {
    log_step "Step 3: Installing chaincode package on all peers..."

    local package_file="$1"
    local package_basename
    package_basename=$(basename "${package_file}")

    # The chaincode directory is mounted in CLI at /opt/gopath/src/github.com/chaincode
    # Package is at chaincode/packages/ which maps to /opt/gopath/src/github.com/chaincode/packages/
    local cli_package_path="/opt/gopath/src/github.com/chaincode/packages/${package_basename}"

    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r org_name msp_id peer_host peer_port <<< "${org_config}"

        log_info "Installing on ${peer_host}..."

        local env_script
        env_script=$(set_org_env_cli "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}")

        local result
        result=$(docker exec cli bash -c "
            ${env_script}
            peer lifecycle chaincode install ${cli_package_path} 2>&1
        ")

        log_verbose "Install result: ${result}"

        # Extract package ID from first successful install (macOS compatible)
        if [[ -z "${PACKAGE_ID}" ]]; then
            PACKAGE_ID=$(echo "${result}" | grep -o 'Chaincode code package identifier: [^ ]*' | sed 's/Chaincode code package identifier: //' | head -1)
            if [[ -z "${PACKAGE_ID}" ]]; then
                PACKAGE_ID=$(echo "${result}" | grep -o 'Package ID: [^,]*' | sed 's/Package ID: //' | head -1)
            fi
        fi

        log_success "Installed on ${peer_host}"
    done

    # If we still don't have package ID, query for it
    if [[ -z "${PACKAGE_ID}" ]]; then
        log_info "Querying for package ID..."
        IFS=':' read -r org_name msp_id peer_host peer_port <<< "${ORG_CONFIGS[0]}"
        local env_script
        env_script=$(set_org_env_cli "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}")

        PACKAGE_ID=$(docker exec cli bash -c "
            ${env_script}
            peer lifecycle chaincode queryinstalled 2>&1 | grep '${CC_NAME}_${CC_VERSION}' | grep -o 'Package ID: [^,]*' | sed 's/Package ID: //' | head -1
        ")
    fi

    if [[ -z "${PACKAGE_ID}" ]]; then
        log_error "Failed to obtain package ID"
        exit 1
    fi

    log_success "Package ID: ${PACKAGE_ID}"
}

start_chaincode_container() {
    log_step "Step 4: Starting chaincode container..."

    log_info "Starting chaincode container with package ID: ${PACKAGE_ID}"

    # Export environment variables and start the chaincode container
    export CHAINCODE_ID="${PACKAGE_ID}"
    export CC_VERSION="${CC_VERSION}"

    # Stop existing container if running
    docker stop niop-chaincode 2>/dev/null || true
    docker rm niop-chaincode 2>/dev/null || true

    # Start the chaincode container using docker compose with the chaincode profile
    docker compose -f "${DOCKER_COMPOSE_DIR}/docker-compose.yaml" \
        --profile chaincode \
        up -d niop-chaincode

    # Wait for container to be ready
    log_info "Waiting for chaincode container to be ready..."
    local retries=0
    while [[ ${retries} -lt 30 ]]; do
        if docker logs niop-chaincode 2>&1 | grep -q "Chaincode server starting"; then
            log_success "Chaincode container is running"
            return 0
        fi
        retries=$((retries + 1))
        sleep 1
    done

    log_warn "Chaincode container may not be fully ready, continuing..."
}

approve_chaincode() {
    log_step "Step 5: Approving chaincode for all organizations..."

    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r org_name msp_id peer_host peer_port <<< "${org_config}"

        log_info "Approving for ${msp_id}..."

        local env_script
        env_script=$(set_org_env_cli "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}")

        local approve_cmd="peer lifecycle chaincode approveformyorg \
            -o ${ORDERER_ADDRESS} \
            --channelID ${CHANNEL_NAME} \
            --name ${CC_NAME} \
            --version ${CC_VERSION} \
            --package-id ${PACKAGE_ID} \
            --sequence ${CC_SEQUENCE} \
            --tls \
            --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/orderer.tolling.network/orderers/orderer1.orderer.tolling.network/msp/tlscacerts/tlsca.orderer.tolling.network-cert.pem"

        # Add collections config if available (copy to mounted chaincode/packages if not there)
        local cli_collections_path="/opt/gopath/src/github.com/chaincode/packages/collections_config.json"
        if [[ -f "${COLLECTIONS_CONFIG}" ]]; then
            cp -f "${COLLECTIONS_CONFIG}" "${PACKAGE_DIR}/collections_config.json" 2>/dev/null || true
            approve_cmd="${approve_cmd} --collections-config ${cli_collections_path}"
        fi

        docker exec cli bash -c "
            ${env_script}
            ${approve_cmd}
        "

        log_success "Approved for ${msp_id}"
    done
}

check_commit_readiness() {
    log_info "Checking commit readiness..."

    IFS=':' read -r org_name msp_id peer_host peer_port <<< "${ORG_CONFIGS[0]}"
    local env_script
    env_script=$(set_org_env_cli "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}")

    local check_cmd="peer lifecycle chaincode checkcommitreadiness \
        --channelID ${CHANNEL_NAME} \
        --name ${CC_NAME} \
        --version ${CC_VERSION} \
        --sequence ${CC_SEQUENCE} \
        --output json"

    local cli_collections_path="/opt/gopath/src/github.com/chaincode/packages/collections_config.json"
    if [[ -f "${COLLECTIONS_CONFIG}" ]]; then
        check_cmd="${check_cmd} --collections-config ${cli_collections_path}"
    fi

    local result
    result=$(docker exec cli bash -c "
        ${env_script}
        ${check_cmd} 2>&1
    ")

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

commit_chaincode() {
    log_step "Step 6: Committing chaincode definition..."

    IFS=':' read -r org_name msp_id peer_host peer_port <<< "${ORG_CONFIGS[0]}"
    local env_script
    env_script=$(set_org_env_cli "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}")

    # Build peer connection args
    local peer_conn_args=""
    for org_config in "${ORG_CONFIGS[@]}"; do
        IFS=':' read -r o_name o_msp o_host o_port <<< "${org_config}"
        local o_domain
        o_domain=$(echo "${o_name}" | tr '[:upper:]' '[:lower:]')
        peer_conn_args="${peer_conn_args} --peerAddresses ${o_host}:${o_port}"
        peer_conn_args="${peer_conn_args} --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${o_domain}.tolling.network/peers/${o_host}/tls/ca.crt"
    done

    local commit_cmd="peer lifecycle chaincode commit \
        -o ${ORDERER_ADDRESS} \
        --channelID ${CHANNEL_NAME} \
        --name ${CC_NAME} \
        --version ${CC_VERSION} \
        --sequence ${CC_SEQUENCE} \
        --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/orderer.tolling.network/orderers/orderer1.orderer.tolling.network/msp/tlscacerts/tlsca.orderer.tolling.network-cert.pem \
        ${peer_conn_args}"

    local cli_collections_path="/opt/gopath/src/github.com/chaincode/packages/collections_config.json"
    if [[ -f "${COLLECTIONS_CONFIG}" ]]; then
        commit_cmd="${commit_cmd} --collections-config ${cli_collections_path}"
    fi

    docker exec cli bash -c "
        ${env_script}
        ${commit_cmd}
    "

    log_success "Chaincode definition committed to channel '${CHANNEL_NAME}'"
}

verify_deployment() {
    log_step "Step 7: Verifying chaincode deployment..."

    IFS=':' read -r org_name msp_id peer_host peer_port <<< "${ORG_CONFIGS[0]}"
    local env_script
    env_script=$(set_org_env_cli "${org_name}" "${msp_id}" "${peer_host}" "${peer_port}")

    local result
    result=$(docker exec cli bash -c "
        ${env_script}
        peer lifecycle chaincode querycommitted --channelID ${CHANNEL_NAME} --name ${CC_NAME} --output json 2>&1
    ")

    log_verbose "Query result: ${result}"

    if echo "${result}" | grep -q "\"name\": \"${CC_NAME}\""; then
        log_success "Chaincode '${CC_NAME}' is committed on channel '${CHANNEL_NAME}'"

        local version sequence
        version=$(echo "${result}" | grep -o '"version": "[^"]*"' | sed 's/"version": "//; s/"$//' | head -1)
        sequence=$(echo "${result}" | grep -o '"sequence": [0-9]*' | sed 's/"sequence": //' | head -1)
        version="${version:-unknown}"
        sequence="${sequence:-unknown}"

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
    echo "            Chaincode as a Service (ccaas) Deployment Complete"
    echo "=============================================================================="
    echo ""
    echo "Chaincode Details:"
    echo "  Name:       ${CC_NAME}"
    echo "  Version:    ${CC_VERSION}"
    echo "  Sequence:   ${CC_SEQUENCE}"
    echo "  Channel:    ${CHANNEL_NAME}"
    echo "  Package ID: ${PACKAGE_ID}"
    echo ""
    echo "Chaincode Server:"
    echo "  Container:  niop-chaincode"
    echo "  Address:    ${CC_SERVER_ADDRESS}"
    echo "  Port:       ${CC_SERVER_PORT}"
    echo ""
    echo "View chaincode logs:"
    echo "  docker logs -f niop-chaincode"
    echo ""
    echo "Test the deployment:"
    echo "  docker exec cli peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{\"function\":\"GetMetadata\",\"Args\":[]}'"
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
            --skip-build)
                SKIP_BUILD="true"
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
    log_info "Tolling.Network - ccaas Chaincode Deployment"
    log_info "=============================================="
    log_info "Chaincode: ${CC_NAME} v${CC_VERSION} (seq ${CC_SEQUENCE})"
    log_info "Channel: ${CHANNEL_NAME}"
    echo ""

    # Run deployment steps
    check_prerequisites
    build_chaincode_image
    local package_file
    package_file=$(create_ccaas_package)
    install_chaincode "${package_file}"
    start_chaincode_container
    approve_chaincode
    check_commit_readiness
    commit_chaincode
    verify_deployment

    print_summary
}

main "$@"
