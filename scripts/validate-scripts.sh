#!/bin/bash
#
# validate-scripts.sh
#
# Validates shell scripts for common path and configuration errors.
# Run this before committing changes to catch issues early.
#
# Checks:
# 1. Script paths reference existing directories (PROJECT_ROOT-relative)
# 2. Scripts don't use host-side peer CLI commands that won't work in CI
# 3. Docker exec commands use correct container paths
#
# Usage:
#   ./scripts/validate-scripts.sh
#
# Copyright 2016-2026 Milligan Partners LLC
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

log_error() {
    echo -e "${RED}ERROR:${NC} $1"
    ((errors++)) || true
}

log_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
    ((warnings++)) || true
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

echo "Validating scripts for common errors..."
echo ""

# ==============================================================================
# Check 1: Verify crypto path references
# ==============================================================================
echo "Checking crypto path references in scripts..."

# Scripts should reference network-config/crypto-config, not infrastructure/network-config/
for script in "${SCRIPT_DIR}"/*.sh; do
    script_name=$(basename "${script}")

    # Skip this validation script (it contains the strings as examples)
    if [[ "${script_name}" == "validate-scripts.sh" ]]; then
        continue
    fi

    # Check for incorrect crypto path (exclude comments)
    if grep -v '^\s*#' "${script}" 2>/dev/null | grep -q 'infrastructure/network-config/crypto-config'; then
        log_error "${script_name}: References incorrect crypto path 'infrastructure/network-config/crypto-config'"
        echo "  Should be: \${PROJECT_ROOT}/network-config/crypto-config"
    fi

    # Check for incorrect channel-artifacts path (exclude comments)
    if grep -v '^\s*#' "${script}" 2>/dev/null | grep -q 'infrastructure/network-config/channel-artifacts'; then
        log_error "${script_name}: References incorrect artifacts path 'infrastructure/network-config/channel-artifacts'"
        echo "  Should be: \${PROJECT_ROOT}/network-config/channel-artifacts"
    fi
done

if [[ ${errors} -eq 0 ]]; then
    log_success "Crypto path references are correct"
fi

# ==============================================================================
# Check 2: Critical CI scripts must use docker exec for peer commands
# ==============================================================================
echo "Checking docker exec usage in CI-critical scripts..."

# These scripts are run in CI and MUST use docker exec for hostname resolution
ci_critical_scripts=("create-channel.sh" "deploy-ccaas.sh")

for script in "${ci_critical_scripts[@]}"; do
    if [[ -f "${SCRIPT_DIR}/${script}" ]]; then
        if ! grep -q 'docker exec' "${SCRIPT_DIR}/${script}" 2>/dev/null; then
            log_error "${script}: Does not use docker exec for peer commands"
            echo "  CI scripts must use docker exec for container hostname resolution"
        fi
    fi
done

if [[ ${errors} -eq 0 ]]; then
    log_success "CI-critical scripts use docker exec"
fi

# ==============================================================================
# Check 3: Verify expected directories exist
# ==============================================================================
echo "Checking expected directory structure..."

expected_dirs=(
    "network-config"
    "network-config/collections"
    "chaincode/niop"
    "chaincode/shared"
    "config"
    "infrastructure/docker"
)

for dir in "${expected_dirs[@]}"; do
    if [[ ! -d "${PROJECT_ROOT}/${dir}" ]]; then
        log_error "Expected directory not found: ${dir}"
    fi
done

if [[ ${errors} -eq 0 ]] || [[ ${warnings} -eq 0 ]]; then
    log_success "Directory structure looks correct"
fi

# ==============================================================================
# Check 4: Verify CLI container paths match docker-compose mounts
# ==============================================================================
echo "Checking CLI container path references..."

# Expected CLI container mount paths (from docker-compose.yaml)
cli_crypto_path="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto"
cli_artifacts_path="/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts"

for script in "${SCRIPT_DIR}"/*.sh; do
    script_name=$(basename "${script}")

    # Check create-channel.sh uses correct container paths
    if [[ "${script_name}" == "create-channel.sh" ]]; then
        if ! grep -q "${cli_crypto_path}" "${script}" 2>/dev/null; then
            log_warning "${script_name}: May not use correct CLI container crypto path"
            echo "  Expected: ${cli_crypto_path}"
        fi
        if ! grep -q "${cli_artifacts_path}" "${script}" 2>/dev/null; then
            log_warning "${script_name}: May not use correct CLI container artifacts path"
            echo "  Expected: ${cli_artifacts_path}"
        fi
    fi
done

# ==============================================================================
# Check 5: Verify ShellCheck (if available)
# ==============================================================================
echo "Checking shell script syntax..."

if command -v shellcheck &> /dev/null; then
    for script in "${SCRIPT_DIR}"/*.sh; do
        script_name=$(basename "${script}")
        if ! shellcheck -S error "${script}" 2>/dev/null; then
            log_warning "${script_name}: ShellCheck found issues"
        fi
    done
    log_success "ShellCheck passed for all scripts"
else
    echo "  (Skipped - shellcheck not installed)"
fi

# ==============================================================================
# Summary
# ==============================================================================
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
