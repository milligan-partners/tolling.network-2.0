#!/bin/bash
#
# network-down.sh
#
# Cleanly shuts down the Tolling.Network Hyperledger Fabric 2.5.x development network.
#
# This script:
# - Stops all docker containers for the network
# - Optionally removes docker volumes (ledger data)
# - Optionally removes generated crypto material and channel artifacts
# - Optionally removes chaincode containers and images
#
# Usage:
#   ./network-down.sh [OPTIONS]
#
# Options:
#   -h, --help           Show this help message
#   -v, --volumes        Remove docker volumes (ledger data)
#   -c, --crypto         Remove crypto material and channel artifacts
#   -a, --all            Remove everything (volumes + crypto + chaincode images)
#   -f, --force          Skip confirmation prompts
#   --verbose            Enable verbose output
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
DOCKER_DIR="${PROJECT_ROOT}/infrastructure/docker"

# Directories to clean
CRYPTO_OUTPUT_DIR="${NETWORK_CONFIG_DIR}/crypto-config"
ARTIFACTS_DIR="${NETWORK_CONFIG_DIR}/channel-artifacts"
PACKAGE_DIR="${PROJECT_ROOT}/chaincode/packages"

# Default values
REMOVE_VOLUMES="${REMOVE_VOLUMES:-false}"
REMOVE_CRYPTO="${REMOVE_CRYPTO:-false}"
REMOVE_ALL="${REMOVE_ALL:-false}"
FORCE="${FORCE:-false}"
VERBOSE="${VERBOSE:-false}"

# Docker compose file location
COMPOSE_FILE="${DOCKER_DIR}/docker-compose.yaml"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-tolling}"

# Network name pattern for filtering containers
NETWORK_NAME_PATTERN="tolling"

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

Shut down the Tolling.Network development network.

Options:
  -h, --help           Show this help message
  -v, --volumes        Remove docker volumes (ledger data)
  -c, --crypto         Remove crypto material and channel artifacts
  -a, --all            Remove everything (volumes + crypto + chaincode images)
  -f, --force          Skip confirmation prompts
  --verbose            Enable verbose output

Environment Variables:
  COMPOSE_PROJECT      Docker compose project name (default: tolling)
  COMPOSE_FILE         Path to docker-compose.yaml

Examples:
  $(basename "$0")                  # Stop containers only
  $(basename "$0") -v               # Stop and remove volumes
  $(basename "$0") -c               # Stop and remove crypto material
  $(basename "$0") -a               # Full cleanup
  $(basename "$0") -a -f            # Full cleanup without prompts

Cleanup Levels:
  Default:    Stop containers (data preserved)
  --volumes:  + Remove ledger data (CouchDB, peer data)
  --crypto:   + Remove certificates and channel artifacts
  --all:      + Remove chaincode containers and images
EOF
}

# ==============================================================================
# Confirmation
# ==============================================================================

confirm() {
    local message="$1"

    if [[ "${FORCE}" == "true" ]]; then
        return 0
    fi

    echo -e "${YELLOW}${message}${NC}"
    read -r -p "Continue? [y/N] " response
    case "${response}" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ==============================================================================
# Docker Operations
# ==============================================================================

stop_containers() {
    log_info "Stopping docker containers..."

    # Try docker-compose first
    if [[ -f "${COMPOSE_FILE}" ]]; then
        log_verbose "Using docker-compose file: ${COMPOSE_FILE}"
        (cd "$(dirname "${COMPOSE_FILE}")" && docker-compose down 2>/dev/null) || true
    fi

    # Also stop any containers matching our network pattern
    local containers
    containers=$(docker ps -a --filter "name=${NETWORK_NAME_PATTERN}" --format "{{.Names}}" 2>/dev/null || echo "")

    if [[ -n "${containers}" ]]; then
        log_verbose "Stopping additional containers: ${containers}"
        echo "${containers}" | xargs -r docker stop 2>/dev/null || true
        echo "${containers}" | xargs -r docker rm -f 2>/dev/null || true
    fi

    # Stop orderer containers
    local orderer_containers
    orderer_containers=$(docker ps -a --filter "name=orderer" --format "{{.Names}}" 2>/dev/null || echo "")
    if [[ -n "${orderer_containers}" ]]; then
        log_verbose "Stopping orderer containers: ${orderer_containers}"
        echo "${orderer_containers}" | xargs -r docker stop 2>/dev/null || true
        echo "${orderer_containers}" | xargs -r docker rm -f 2>/dev/null || true
    fi

    # Stop peer containers
    local peer_containers
    peer_containers=$(docker ps -a --filter "name=peer" --format "{{.Names}}" 2>/dev/null || echo "")
    if [[ -n "${peer_containers}" ]]; then
        log_verbose "Stopping peer containers: ${peer_containers}"
        echo "${peer_containers}" | xargs -r docker stop 2>/dev/null || true
        echo "${peer_containers}" | xargs -r docker rm -f 2>/dev/null || true
    fi

    # Stop CouchDB containers
    local couchdb_containers
    couchdb_containers=$(docker ps -a --filter "name=couchdb" --format "{{.Names}}" 2>/dev/null || echo "")
    couchdb_containers+=$(docker ps -a --filter "name=db.peer" --format "{{.Names}}" 2>/dev/null || echo "")
    if [[ -n "${couchdb_containers}" ]]; then
        log_verbose "Stopping CouchDB containers: ${couchdb_containers}"
        echo "${couchdb_containers}" | xargs -r docker stop 2>/dev/null || true
        echo "${couchdb_containers}" | xargs -r docker rm -f 2>/dev/null || true
    fi

    # Stop CA containers
    local ca_containers
    ca_containers=$(docker ps -a --filter "name=ca" --format "{{.Names}}" 2>/dev/null || echo "")
    if [[ -n "${ca_containers}" ]]; then
        log_verbose "Stopping CA containers: ${ca_containers}"
        echo "${ca_containers}" | xargs -r docker stop 2>/dev/null || true
        echo "${ca_containers}" | xargs -r docker rm -f 2>/dev/null || true
    fi

    # Stop CLI container
    docker stop cli 2>/dev/null || true
    docker rm cli 2>/dev/null || true

    log_success "Containers stopped"
}

remove_volumes() {
    log_info "Removing docker volumes..."

    # Remove volumes from docker-compose
    if [[ -f "${COMPOSE_FILE}" ]]; then
        (cd "$(dirname "${COMPOSE_FILE}")" && docker-compose down -v 2>/dev/null) || true
    fi

    # Remove any volumes matching our patterns
    local volumes
    volumes=$(docker volume ls --filter "name=${NETWORK_NAME_PATTERN}" -q 2>/dev/null || echo "")
    volumes+=$(docker volume ls --filter "name=peer" -q 2>/dev/null || echo "")
    volumes+=$(docker volume ls --filter "name=orderer" -q 2>/dev/null || echo "")
    volumes+=$(docker volume ls --filter "name=couchdb" -q 2>/dev/null || echo "")

    if [[ -n "${volumes}" ]]; then
        log_verbose "Removing volumes: ${volumes}"
        echo "${volumes}" | sort -u | xargs -r docker volume rm -f 2>/dev/null || true
    fi

    log_success "Volumes removed"
}

remove_chaincode_containers() {
    log_info "Removing chaincode containers..."

    # Find and remove chaincode containers (dev-peer* pattern)
    local cc_containers
    cc_containers=$(docker ps -a --filter "name=dev-peer" --format "{{.Names}}" 2>/dev/null || echo "")

    if [[ -n "${cc_containers}" ]]; then
        log_verbose "Removing chaincode containers: ${cc_containers}"
        echo "${cc_containers}" | xargs -r docker stop 2>/dev/null || true
        echo "${cc_containers}" | xargs -r docker rm -f 2>/dev/null || true
    fi

    log_success "Chaincode containers removed"
}

remove_chaincode_images() {
    log_info "Removing chaincode images..."

    # Find and remove chaincode images
    local cc_images
    cc_images=$(docker images --filter "reference=dev-peer*" -q 2>/dev/null || echo "")

    if [[ -n "${cc_images}" ]]; then
        log_verbose "Removing chaincode images"
        echo "${cc_images}" | xargs -r docker rmi -f 2>/dev/null || true
    fi

    log_success "Chaincode images removed"
}

remove_network() {
    log_info "Removing docker network..."

    # Remove network if exists
    docker network rm "${COMPOSE_PROJECT}_basic" 2>/dev/null || true
    docker network rm "${NETWORK_NAME_PATTERN}" 2>/dev/null || true
    docker network rm basic 2>/dev/null || true

    log_success "Network removed"
}

# ==============================================================================
# File Cleanup
# ==============================================================================

remove_crypto_material() {
    log_info "Removing crypto material and channel artifacts..."

    if [[ -d "${CRYPTO_OUTPUT_DIR}" ]]; then
        log_verbose "Removing: ${CRYPTO_OUTPUT_DIR}"
        rm -rf "${CRYPTO_OUTPUT_DIR}"
    fi

    if [[ -d "${ARTIFACTS_DIR}" ]]; then
        log_verbose "Removing: ${ARTIFACTS_DIR}"
        rm -rf "${ARTIFACTS_DIR}"
    fi

    if [[ -d "${PACKAGE_DIR}" ]]; then
        log_verbose "Removing: ${PACKAGE_DIR}"
        rm -rf "${PACKAGE_DIR}"
    fi

    log_success "Crypto material and artifacts removed"
}

# ==============================================================================
# Summary
# ==============================================================================

print_summary() {
    echo ""
    echo "=============================================================================="
    echo "                    Network Shutdown Complete"
    echo "=============================================================================="
    echo ""
    echo "Actions performed:"
    echo "  - Stopped and removed docker containers"

    if [[ "${REMOVE_VOLUMES}" == "true" ]] || [[ "${REMOVE_ALL}" == "true" ]]; then
        echo "  - Removed docker volumes (ledger data)"
    fi

    if [[ "${REMOVE_CRYPTO}" == "true" ]] || [[ "${REMOVE_ALL}" == "true" ]]; then
        echo "  - Removed crypto material and channel artifacts"
    fi

    if [[ "${REMOVE_ALL}" == "true" ]]; then
        echo "  - Removed chaincode containers and images"
    fi

    echo ""
    echo "To restart the network:"

    if [[ "${REMOVE_CRYPTO}" == "true" ]] || [[ "${REMOVE_ALL}" == "true" ]]; then
        echo "  1. Generate crypto material:  ./scripts/network-init.sh"
        echo "  2. Start containers:          docker-compose up -d"
        echo "  3. Create channel:            ./scripts/create-channel.sh"
        echo "  4. Deploy chaincode:          ./scripts/deploy-chaincode.sh"
    else
        echo "  1. Start containers:          docker-compose up -d"
        if [[ "${REMOVE_VOLUMES}" == "true" ]] || [[ "${REMOVE_ALL}" == "true" ]]; then
            echo "  2. Create channel:            ./scripts/create-channel.sh"
            echo "  3. Deploy chaincode:          ./scripts/deploy-chaincode.sh"
        fi
    fi

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
            -v|--volumes)
                REMOVE_VOLUMES="true"
                shift
                ;;
            -c|--crypto)
                REMOVE_CRYPTO="true"
                shift
                ;;
            -a|--all)
                REMOVE_ALL="true"
                REMOVE_VOLUMES="true"
                REMOVE_CRYPTO="true"
                shift
                ;;
            -f|--force)
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
    log_info "Tolling.Network - Network Shutdown"
    log_info "=============================================="
    echo ""

    # Show what will be cleaned
    echo "This will:"
    echo "  - Stop and remove all network containers"

    if [[ "${REMOVE_VOLUMES}" == "true" ]]; then
        echo "  - Remove docker volumes (ledger data will be LOST)"
    fi

    if [[ "${REMOVE_CRYPTO}" == "true" ]]; then
        echo "  - Remove crypto material and channel artifacts"
    fi

    if [[ "${REMOVE_ALL}" == "true" ]]; then
        echo "  - Remove chaincode containers and images"
    fi

    echo ""

    # Confirm if not forced
    if [[ "${REMOVE_VOLUMES}" == "true" ]] || [[ "${REMOVE_CRYPTO}" == "true" ]]; then
        if ! confirm "WARNING: This will remove data that cannot be recovered!"; then
            log_info "Shutdown cancelled"
            exit 0
        fi
    fi

    # Perform shutdown operations
    stop_containers

    if [[ "${REMOVE_VOLUMES}" == "true" ]]; then
        remove_volumes
    fi

    if [[ "${REMOVE_ALL}" == "true" ]]; then
        remove_chaincode_containers
        remove_chaincode_images
    fi

    remove_network

    if [[ "${REMOVE_CRYPTO}" == "true" ]]; then
        remove_crypto_material
    fi

    print_summary
}

main "$@"
