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
export CHANNEL_NAME=mychannel
export COMPOSE_PROJECT_NAME=net 
#docker-compose -f docker-compose.yml down

function generateCerts() {
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi
  echo
  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"

  if [ -d "crypto-config" ]; then
    rm -Rf crypto-config
  fi
  set -x
  cryptogen generate --config=./crypto-config.yaml
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
  echo
}

function replacePrivateKey() {

cp docker-compose-template.yml docker-compose.yml
CURRENT_DIR=$PWD
cd crypto-config/peerOrganizations/org1.ruuftop.com/ca/
PRIV_KEY=$(ls *_sk)
cd "$CURRENT_DIR"
sed -it "s/CA_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yml
#rm docker-compose-e2e.yamlt

}

generateCerts
replacePrivateKey

# generate genesis block for orderer
configtxgen -profile OneOrgOrdererGenesis -outputBlock ./config/genesis.block
if [ "$?" -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi
sudo chmod -R 777 config
# generate channel configuration transaction
configtxgen -profile OneOrgChannel -outputCreateChannelTx ./config/channel.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

# generate anchor peer transaction
configtxgen -profile OneOrgChannel -outputAnchorPeersUpdate ./config/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for Org1MSP..."
  exit 1
fi


docker-compose -f docker-compose.yml up -d ca.ruuftop.com orderer.ruuftop.com peer0.org1.ruuftop.com couchdb cli
docker ps -a

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=90
#echo ${FABRIC_START_TIMEOUT}
sleep 10

# Create the channel
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.ruuftop.com/msp" peer0.org1.ruuftop.com peer channel create -o orderer.ruuftop.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
# Join peer0.org1.ruuftop.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.ruuftop.com/msp" peer0.org1.ruuftop.com peer channel join -b mychannel.block
