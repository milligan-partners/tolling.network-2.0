#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# ============================================================================
# WARNING: LEGACY REFERENCE SCRIPT — DO NOT USE IN PRODUCTION
# ============================================================================
# This script is from 2019-2020 and is kept for reference only.
# For 2.0 development, use Hyperledger Bevel or Fabric test-network scripts.
# ============================================================================

# Strict mode: exit on error, undefined vars, and pipe failures
set -euo pipefail

# Configuration - must match start.sh
readonly CHANNEL_NAME="${CHANNEL_NAME:-samplechannel}"
readonly COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-sampleproject}"

# Project-specific container label for filtering
readonly PROJECT_LABEL="com.docker.compose.project=${COMPOSE_PROJECT_NAME}"

# Logging helper
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error_exit() {
  log "ERROR: $1" >&2
  exit 1
}

# Validate docker is available
command -v docker >/dev/null 2>&1 || error_exit "docker is required but not installed"
command -v docker-compose >/dev/null 2>&1 || error_exit "docker-compose is required but not installed"

main() {
  log "Stopping docker-compose services..."
  docker-compose -f docker-compose.yml stop || true

  log "Removing docker-compose containers..."
  docker-compose -f docker-compose.yml kill || true
  docker-compose -f docker-compose.yml down --volumes --remove-orphans || true

  # Remove only containers from this project (not ALL containers like the legacy script did)
  log "Removing project-specific containers..."
  local containers
  containers=$(docker ps -aq --filter "label=${PROJECT_LABEL}" 2>/dev/null || true)
  if [[ -n "${containers}" ]]; then
    echo "${containers}" | xargs docker rm -f || true
  fi

  # Remove chaincode docker images (dev-* images created by Fabric)
  log "Removing chaincode images..."
  local chaincode_images
  chaincode_images=$(docker images "dev-*" -q 2>/dev/null || true)
  if [[ -n "${chaincode_images}" ]]; then
    echo "${chaincode_images}" | xargs docker rmi -f || true
  fi

  # Remove project network if it exists
  log "Removing project network..."
  docker network rm "${COMPOSE_PROJECT_NAME}_basic" 2>/dev/null || true

  log "Teardown complete. Your system is now clean."
}

main "$@"
