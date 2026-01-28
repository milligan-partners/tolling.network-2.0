#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
set -ev
VERSION=$1
echo "Upgrade Version $VERSION"
# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
export CHANNEL_NAME=ctocchannel
export COMPOSE_PROJECT_NAME=ctocproject
#docker-compose -f docker-compose.yml down

function installCC() {
    echo $VERSION
  docker exec \
    -e "CORE_PEER_ADDRESS=$1" \
    -e "CORE_PEER_LOCALMSPID=$2" \
    -e "CORE_PEER_MSPCONFIGPATH=$3" \
    cli peer chaincode upgrade \
    -n ctoc_cc \
    -v $VERSION \
    -l node \
    -p /opt/gopath/src/github.com/CTOCchaincode/
}

# # wait for Hyperledger Fabric to start
# # incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=90
export CORE_CHAINCODE_DEPLOYTIMEOUT=300s
export CORE_CHAINCODE_STARTUPTIMEOUT=300s

TCAEnv=("peer0.tca.com:7051" "TCA" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/tca.com/users/Admin@tca.com/msp" \
  "/etc/hyperledger/configtx/TCAanchors.tx")

BATAEnv=("peer0.bata.com:7051" "BATA" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/bata.com/users/Admin@bata.com/msp" \
  "/etc/hyperledger/configtx/BATAanchors.tx")

SANDAGEnv=("peer0.sandag.com:7051" "SANDAG" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/sandag.com/users/Admin@sandag.com/msp" \
  "/etc/hyperledger/configtx/SANDAGanchors.tx")

REPORTEnv=("peer0.report.com:7051" "REPORT" \
  "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/report.com/users/Admin@report.com/msp" \
  "/etc/hyperledger/configtx/REPORTanchors.tx")


installCC "${TCAEnv[@]}"

installCC "${BATAEnv[@]}"

installCC "${SANDAGEnv[@]}"

installCC "${REPORTEnv[@]}"

sleep 5
docker exec cli peer chaincode instantiate \
  -o orderer.ruuftop.com:7050 -C $CHANNEL_NAME \
  -n ctoc_cc -l node -v $VERSION -c '{"Args":["init"]}' \
  -P "AND ('TCA.member', 'BATA.member', 'SANDAG.member')" \
  --collections-config  /opt/gopath/src/github.com/CTOCchaincode/collections_config.json