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
#
# Known issues in this script:
# - Uses deprecated Fabric 1.x chaincode lifecycle (peer chaincode instantiate)
# - Hardcoded endorsement policies
# - No TLS configuration
# - Sleep-based synchronization (fragile)
# ============================================================================

# Strict mode: exit on error, undefined vars, and pipe failures
set -euo pipefail

# Fail loudly if any command in a pipeline fails
IFS=$'\n\t'

# Configuration
readonly CHANNEL_NAME="${CHANNEL_NAME:-samplechannel}"
readonly COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-sampleproject}"
readonly FABRIC_START_TIMEOUT="${FABRIC_START_TIMEOUT:-90}"

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
export CHANNEL_NAME
export COMPOSE_PROJECT_NAME

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

joinChannel() {
  local peer_address="$1"
  local msp_id="$2"
  local msp_path="$3"
  local anchor_tx="$4"

  log "Joining channel for ${msp_id}..."
  docker exec -e "CORE_PEER_ADDRESS=${peer_address}" \
              -e "CORE_PEER_LOCALMSPID=${msp_id}" \
              -e "CORE_PEER_MSPCONFIGPATH=${msp_path}" \
              cli peer channel join -b "${CHANNEL_NAME}.block"

  docker exec -e "CORE_PEER_ADDRESS=${peer_address}" \
              -e "CORE_PEER_LOCALMSPID=${msp_id}" \
              -e "CORE_PEER_MSPCONFIGPATH=${msp_path}" \
              cli peer channel update -o orderer.example.com:7050 \
              -c "${CHANNEL_NAME}" -f "${anchor_tx}"
}

installCC() {
  local peer_address="$1"
  local msp_id="$2"
  local msp_path="$3"

  log "Installing chaincode on ${msp_id}..."
  docker exec \
    -e "CORE_PEER_ADDRESS=${peer_address}" \
    -e "CORE_PEER_LOCALMSPID=${msp_id}" \
    -e "CORE_PEER_MSPCONFIGPATH=${msp_path}" \
    cli peer chaincode install \
    -n sample_cc \
    -v 1.0 \
    -l node \
    -p /opt/gopath/src/github.com/chaincode/
}

queryTest() {
  local peer_address="$1"
  local msp_id="$2"
  local msp_path="$3"

  log "Querying chaincode on ${msp_id}..."
  docker exec -e "CORE_PEER_ADDRESS=${peer_address}" \
              -e "CORE_PEER_LOCALMSPID=${msp_id}" \
              -e "CORE_PEER_MSPCONFIGPATH=${msp_path}" \
              cli peer chaincode query -C "${CHANNEL_NAME}" -n sample_cc -c '{"Args":["query","a"]}'
}

main() {
  log "Building ELK container..."
  if [[ -d "elk" ]]; then
    (cd elk && docker build . -t elk)
  else
    log "Warning: elk directory not found, skipping ELK build"
  fi

  log "Starting docker-compose services..."
  docker-compose -f docker-compose.yml up -d
  docker ps -a

  log "Waiting ${FABRIC_START_TIMEOUT}s for Hyperledger Fabric to start..."
  sleep 10

  log "Creating channel ${CHANNEL_NAME}..."
  docker exec cli peer channel create -o orderer.example.com:7050 \
              -c "${CHANNEL_NAME}" \
              -f /etc/hyperledger/configtx/channel.tx

  # Organization configurations
  declare -a Org1Env=(
    "peer0.org1.example.com:7051"
    "Org1MSP"
    "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
    "/etc/hyperledger/configtx/Org1anchors.tx"
  )

  declare -a Org2Env=(
    "peer0.org2.example.com:7051"
    "Org2MSP"
    "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"
    "/etc/hyperledger/configtx/Org2anchors.tx"
  )

  declare -a Org3Env=(
    "peer0.org3.example.com:7051"
    "Org3MSP"
    "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp"
    "/etc/hyperledger/configtx/Org3anchors.tx"
  )

  declare -a Org4Env=(
    "peer0.org4.example.com:7051"
    "Org4MSP"
    "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp"
    "/etc/hyperledger/configtx/Org4anchors.tx"
  )

  joinChannel "${Org1Env[@]}"
  joinChannel "${Org2Env[@]}"
  joinChannel "${Org3Env[@]}"
  joinChannel "${Org4Env[@]}"

  installCC "${Org1Env[@]}"
  installCC "${Org2Env[@]}"
  installCC "${Org3Env[@]}"
  installCC "${Org4Env[@]}"

  log "Instantiating chaincode..."
  sleep 5
  docker exec cli peer chaincode instantiate \
    -o orderer.example.com:7050 -C "${CHANNEL_NAME}" \
    -n sample_cc -l node -v 1.0 -c '{"Args":["init"]}' \
    -P "AND ('Org1MSP.member', 'Org2MSP.member', 'Org3MSP.member')" \
    --collections-config /opt/gopath/src/github.com/chaincode/collections_config.json

  sleep 5

  if [[ -f "data_generation/generate_data.sh" ]]; then
    log "Generating sample data..."
    bash data_generation/generate_data.sh
  fi

  log "Restarting ELK..."
  docker-compose restart elk

  log "Network startup complete."
}

main "$@"
