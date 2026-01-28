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
#
# Exit on first error, print all commands.
set -ev
VERSION=$1
echo "Upgrade Version $VERSION"
# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
export CHANNEL_NAME=samplechannel
export COMPOSE_PROJECT_NAME=sampleproject
#docker-compose -f docker-compose.yml down

function installCC() {
    echo $VERSION
  docker exec \
    -e "CORE_PEER_ADDRESS=$1" \
    -e "CORE_PEER_LOCALMSPID=$2" \
    -e "CORE_PEER_MSPCONFIGPATH=$3" \
    cli peer chaincode upgrade \
    -n sample_cc \
    -v $VERSION \
    -l node \
    -p /opt/gopath/src/github.com/chaincode/
}

# # wait for Hyperledger Fabric to start
# # incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=90
export CORE_CHAINCODE_DEPLOYTIMEOUT=300s
export CORE_CHAINCODE_STARTUPTIMEOUT=300s

Org1Env=("peer0.org1.example.com:7051" "Org1MSP" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" \
  "/etc/hyperledger/configtx/Org1anchors.tx")

Org2Env=("peer0.org2.example.com:7051" "Org2MSP" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" \
  "/etc/hyperledger/configtx/Org2anchors.tx")

Org3Env=("peer0.org3.example.com:7051" "Org3MSP" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp" \
  "/etc/hyperledger/configtx/Org3anchors.tx")

Org4Env=("peer0.org4.example.com:7051" "Org4MSP" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp" \
  "/etc/hyperledger/configtx/Org4anchors.tx")


installCC "${Org1Env[@]}"

installCC "${Org2Env[@]}"

installCC "${Org3Env[@]}"

installCC "${Org4Env[@]}"

sleep 5
docker exec cli peer chaincode instantiate \
  -o orderer.example.com:7050 -C $CHANNEL_NAME \
  -n sample_cc -l node -v $VERSION -c '{"Args":["init"]}' \
  -P "AND ('Org1MSP.member', 'Org2MSP.member', 'Org3MSP.member')" \
  --collections-config  /opt/gopath/src/github.com/chaincode/collections_config.json
