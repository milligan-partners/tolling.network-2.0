Tolling.network is a distributed ledger solution for tolling services. It provides flexible, efficient, and scalable alternatives for agency-to-agency interoperability models and modular interoperability apps for a wide range of third-party services.

Built on Hyperledger Fabric, "a fully-vetted, open source architecture," tolling.network is uniqely suited for enterprise applications.

Read the original white paper: [A Unified Tolling Network](https://milliganpartners.com/unified-tolling-network/)


Changes made:
Updating to Hyperledger fabric version 1.1 as version 1.1 supports Node JS and it is also the latest version.

Change 1: 
The image versions are being changed to 1.1 everywhere.

Change 2: 
In testPeersDeployment.yaml, I removed the --peer-defaultchain=false flag from the command related to deploying peers. 
reason : https://github.com/hyperledger/composer/issues/3024

Change 3: 
In testPeersDeployment.yaml, I modified the CORE_PEER_GOSSIP_ORGLEADER parameter from true to false.
reason: https://github.com/IBM/blockchain-network-on-kubernetes/issues/7
