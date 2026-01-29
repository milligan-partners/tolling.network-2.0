#!/bin/bash
#
# validate-docker-compose.sh
#
# Validates docker-compose.yaml for common CI compatibility issues.
# Run this before committing changes to catch issues early.
#
# Checks:
# 1. Volume paths are relative to project root (../../ from infrastructure/docker/)
# 2. Parent directories aren't mounted :ro when child mounts need to be created
# 3. Crypto paths exist (if crypto-config is generated)
#
# Usage:
#   ./scripts/validate-docker-compose.sh
#
# Copyright 2016-2026 Milligan Partners LLC
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${PROJECT_ROOT}/infrastructure/docker/docker-compose.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

log_error() {
    echo -e "${RED}ERROR:${NC} $1"
    ((errors++))
}

log_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
    ((warnings++))
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

echo "Validating docker-compose.yaml for CI compatibility..."
echo ""

# Check 1: Verify compose file exists
if [[ ! -f "${COMPOSE_FILE}" ]]; then
    log_error "docker-compose.yaml not found at ${COMPOSE_FILE}"
    exit 1
fi

# Check 2: Volume paths should use ../../ prefix (relative to infrastructure/docker/)
echo "Checking volume path prefixes..."
bad_paths=$(grep -n '^\s*-.*:/.*' "${COMPOSE_FILE}" | grep -E '\.\./network-config|\.\.config' | grep -v '../../' || true)
if [[ -n "${bad_paths}" ]]; then
    log_error "Found volume paths with incorrect relative paths (should use ../../ from infrastructure/docker/):"
    echo "${bad_paths}"
else
    log_success "Volume paths use correct ../../ prefix"
fi

# Check 3: Parent :ro mount conflict detection
# If a directory is mounted as :ro, child mounts inside it will fail
echo "Checking for parent :ro mount conflicts..."

# Extract all volume mounts for peer services
peer_volumes=$(grep -A 50 'peer0.org[1-4].tolling.network:' "${COMPOSE_FILE}" | grep -E '^\s*- .*:/etc/hyperledger/fabric' || true)

# Check if config is mounted :ro while msp/tls are children
config_ro=$(echo "${peer_volumes}" | grep '/etc/hyperledger/fabric:ro' || true)
msp_mount=$(echo "${peer_volumes}" | grep '/etc/hyperledger/fabric/msp' || true)

if [[ -n "${config_ro}" ]] && [[ -n "${msp_mount}" ]]; then
    log_error "Parent directory /etc/hyperledger/fabric is mounted as :ro but has child mounts (msp, tls)"
    echo "  This causes 'read-only file system' errors on GitHub Actions"
    echo "  Fix: Remove :ro from the parent config mount"
else
    log_success "No parent :ro mount conflicts detected"
fi

# Check 4: Verify expected volume structure for peers
echo "Checking peer volume structure..."
for org in 1 2 3 4; do
    peer_section=$(grep -A 20 "peer0.org${org}.tolling.network:" "${COMPOSE_FILE}" | grep -A 10 'volumes:' | head -10)

    # Should have config, msp, tls, and production volumes
    # Config mount ends with /etc/hyperledger/fabric (optionally followed by : or newline)
    if ! echo "${peer_section}" | grep -qE ':/etc/hyperledger/fabric($|:)'; then
        log_warning "peer0.org${org}: Missing config volume mount"
    fi
    if ! echo "${peer_section}" | grep -q '/etc/hyperledger/fabric/msp'; then
        log_warning "peer0.org${org}: Missing msp volume mount"
    fi
    if ! echo "${peer_section}" | grep -q '/etc/hyperledger/fabric/tls'; then
        log_warning "peer0.org${org}: Missing tls volume mount"
    fi
done

if [[ ${warnings} -eq 0 ]]; then
    log_success "Peer volume structure looks correct"
fi

# Check 5: Verify crypto paths exist (if generated)
echo "Checking crypto material paths..."
CRYPTO_DIR="${PROJECT_ROOT}/network-config/crypto-config"
if [[ -d "${CRYPTO_DIR}" ]]; then
    # Verify expected org directories exist
    for org in org1 org2 org3 org4; do
        peer_msp="${CRYPTO_DIR}/peerOrganizations/${org}.tolling.network/peers/peer0.${org}.tolling.network/msp"
        if [[ ! -d "${peer_msp}" ]]; then
            log_warning "Crypto material missing for ${org}: ${peer_msp}"
        fi
    done

    orderer_msp="${CRYPTO_DIR}/ordererOrganizations/orderer.tolling.network/orderers/orderer1.orderer.tolling.network/msp"
    if [[ ! -d "${orderer_msp}" ]]; then
        log_warning "Crypto material missing for orderer1"
    fi

    if [[ ${warnings} -eq 0 ]]; then
        log_success "Crypto material paths exist"
    fi
else
    echo "  (Skipped - crypto-config not generated yet. Run 'make network-init' first)"
fi

# Check 6: Verify YAML syntax
echo "Checking YAML syntax..."
if command -v docker &> /dev/null; then
    if docker compose -f "${COMPOSE_FILE}" config > /dev/null 2>&1; then
        log_success "YAML syntax is valid"
    else
        log_error "Invalid YAML syntax in docker-compose.yaml"
        docker compose -f "${COMPOSE_FILE}" config 2>&1 | head -20
    fi
else
    echo "  (Skipped - docker not available)"
fi

# Summary
echo ""
echo "================================"
if [[ ${errors} -gt 0 ]]; then
    echo -e "${RED}Validation FAILED${NC}: ${errors} error(s), ${warnings} warning(s)"
    exit 1
elif [[ ${warnings} -gt 0 ]]; then
    echo -e "${YELLOW}Validation PASSED with warnings${NC}: ${warnings} warning(s)"
    exit 0
else
    echo -e "${GREEN}Validation PASSED${NC}"
    exit 0
fi
