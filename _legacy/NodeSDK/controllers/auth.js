"use strict";
const { sign } = require("../utils/jwt-utils");
const FabricCAServices = require('fabric-ca-client');
const Client = require('fabric-client');
const { FileSystemWallet, Gateway, X509WalletMixin, } = require('fabric-network');
const fs = require('fs');
const path = require('path');

const ccpPath = path.resolve(__dirname, '..', 'connection.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);

const registerUser = async (user, password, wallet) => {
  const gateway = new Gateway();
  await gateway.connect(ccp, { wallet, identity: 'admin', discovery: { enabled: false } });

  // Get the CA client object from the gateway for interacting with the CA.
  // var client = Client.loadFromConfig('fabric-ca-client-config.yaml');
  const ca = gateway.getClient().getCertificateAuthority();
  const adminIdentity = gateway.getCurrentIdentity();
  // Register the user, enroll the user, and import the new identity into the wallet.
  try {
    await ca.register({ affiliation: 'org1.department1', enrollmentID: user, enrollmentSecret: password, role: 'client', maxEnrollments: -1}, adminIdentity);
  } catch (error) {
    
  }
  
  const enrollment = await ca.enroll({ enrollmentID: user, enrollmentSecret: password });
  const userIdentity = X509WalletMixin.createIdentity('Org1MSP', enrollment.certificate, enrollment.key.toBytes());
  wallet.import(user, userIdentity);
  console.log('Successfully registered and enrolled user  and imported it into the wallet');
}

module.exports = {
  authenticate: async (req, res, next) => {
    if (req.body.username == "peer0" && req.body.password == "userpw") {
      var user = req.body.username;
      var password = req.body.password
      let token = sign(
        {
          username: req.body.username
        },
        {
          issuer: "tolling.network"
        }
      );

      const walletPath = path.join(process.cwd(), 'wallet');
      const wallet = new FileSystemWallet(walletPath);
      console.log(`Wallet path: ${walletPath}`);

      // Check to see if we've already enrolled the user.
      const userExists = await wallet.exists(user);
      if (!userExists) {
        console.log("Registering and enrolling user " + user);
        registerUser(user, password, wallet);
      }

      return res.send({
        token: token
      });
    }

    return res.status(401).send("Wrong username or password");
  }
};
