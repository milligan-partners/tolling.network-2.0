Create a VM on GCP or any other cloud platform.

1. run the prerequisites.sh script

2. Restart the terminal and run the below command
      `curl -sSL http://bit.ly/2ysbOFE | bash -s -- 1.4.1 1.4.1 0.4.15`

3. update the path env variable to point to the bin folder in fabric samples
      `export PATH=<path to download location>/bin:$PATH`

4. Restart the terminal again

5. Start the network
  `bash start.sh`

6. Install and Instantiate chaincode

     6.1 Enter the cli container
          `docker exec -it cli bash`
          
     6.2 Install chaincode
           `peer chaincode install -n mycc -v 1.0 -l node -p /opt/gopath/src/github.com/chaincode_example02/`

     6.3 Instantiate chaincode
           `peer chaincode instantiate -o orderer.ruuftop.com:7050 -C mychannel -n mycc -l node -v 1.0 -c '{"Args":["init"]}'`
