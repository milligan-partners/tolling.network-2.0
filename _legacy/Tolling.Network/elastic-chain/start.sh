#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
set -ev

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
export CHANNEL_NAME=ctocchannel
export COMPOSE_PROJECT_NAME=ctocproject
export PRIVATE_CHANNEL_NAME=ctocprivatechannel
#docker-compose -f docker-compose.yml down

cd elk
docker build . -t elk
cd ../

function joinChannel() {
  docker exec -e "CORE_PEER_ADDRESS=$1" \
            -e "CORE_PEER_LOCALMSPID=$2" \
            -e "CORE_PEER_MSPCONFIGPATH=$3" \
            cli peer channel join -b ${CHANNEL_NAME}.block

  docker exec -e "CORE_PEER_ADDRESS=$1" \
              -e "CORE_PEER_LOCALMSPID=$2" \
              -e "CORE_PEER_MSPCONFIGPATH=$3" \
              cli peer channel update -o orderer.ruuftop.com:7050 \
              -c $CHANNEL_NAME -f $4
}


function joinPrivateChannel() {
  docker exec -e "CORE_PEER_ADDRESS=$1" \
            -e "CORE_PEER_LOCALMSPID=$2" \
            -e "CORE_PEER_MSPCONFIGPATH=$3" \
            cli peer channel join -b ${PRIVATE_CHANNEL_NAME}.block

  docker exec -e "CORE_PEER_ADDRESS=$1" \
              -e "CORE_PEER_LOCALMSPID=$2" \
              -e "CORE_PEER_MSPCONFIGPATH=$3" \
              cli peer channel update -o orderer.ruuftop.com:7050 \
              -c $PRIVATE_CHANNEL_NAME -f $4
}

function installCC() {
  docker exec \
    -e "CORE_PEER_ADDRESS=$1" \
    -e "CORE_PEER_LOCALMSPID=$2" \
    -e "CORE_PEER_MSPCONFIGPATH=$3" \
    cli peer chaincode install \
    -n ctoc_cc \
    -v 1.0 \
    -l node \
    -p /opt/gopath/src/github.com/CTOCchaincode/
    
}

function queryTest() {
  docker exec -e "CORE_PEER_ADDRESS=$1" \
            -e "CORE_PEER_LOCALMSPID=$2" \
            -e "CORE_PEER_MSPCONFIGPATH=$3" \
            cli peer chaincode query -C ${CHANNEL_NAME} -n ctoc_cc -c '{"Args":["query","a"]}'
}

docker-compose -f docker-compose.yml up -d 
docker ps -a

# # wait for Hyperledger Fabric to start
# # incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=90
export CORE_CHAINCODE_DEPLOYTIMEOUT=300s
export CORE_CHAINCODE_STARTUPTIMEOUT=300s


#echo ${FABRIC_START_TIMEOUT}
sleep 10

# # Create the channel

docker pull hyperledger/fabric-ccenv:1.4.7
docker image tag hyperledger/fabric-ccenv:1.4.7 hyperledger/fabric-ccenv:latest

docker exec cli peer channel create -o orderer.ruuftop.com:7050 \
            -c ${CHANNEL_NAME} \
            -f /etc/hyperledger/configtx/channel.tx
            

# # docker exec cli peer channel create -o orderer.ruuftop.com:7050 \
# #             -c ${PRIVATE_CHANNEL_NAME} \
# #             -f /etc/hyperledger/configtx/privatechannel.tx
            
# # docker exec -it cli bash
# # docker exec cli apt-get update && apt-get install -y curl
# # docker exec cli curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
# # docker exec cli nvm install 8.4.0
# # docker exec cli apt-get install -y npm

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
  
sleep 10

joinChannel "${TCAEnv[@]}"

joinChannel "${BATAEnv[@]}"

joinChannel "${SANDAGEnv[@]}"

joinChannel "${REPORTEnv[@]}"

installCC "${TCAEnv[@]}"

installCC "${BATAEnv[@]}"

installCC "${SANDAGEnv[@]}"

installCC "${REPORTEnv[@]}"

sleep 5
docker exec cli peer chaincode instantiate \
  -o orderer.ruuftop.com:7050 -C $CHANNEL_NAME \
  -n ctoc_cc -l node -v 1.0 -c '{"Args":["init"]}' \
  -P "AND ('TCA.member', 'BATA.member', 'SANDAG.member')" \
  --collections-config  /opt/gopath/src/github.com/CTOCchaincode/collections_config.json
# #  --tls true \
# #  --cafile /etc/hyperledger/configtx/tlsca.ruuftop.com-cert.pem
sleep 5 

# # bash data_generation/generate_data.sh
# # docker-compose restart elk
