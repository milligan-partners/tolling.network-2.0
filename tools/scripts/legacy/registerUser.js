/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * ============================================================================
 * WARNING: LEGACY REFERENCE CODE — DO NOT USE IN PRODUCTION
 * ============================================================================
 * This script is from the Fabric SDK v1.x era (2019) and is kept for reference
 * only. It contains hardcoded credentials and uses deprecated APIs.
 *
 * Security issues:
 * - Hardcoded user password ('userpw') on line 49
 * - No TLS configuration
 * - Deprecated fabric-network APIs (FileSystemWallet, X509WalletMixin)
 * - Empty catch block silently swallows registration errors
 *
 * For Fabric 2.5.x, use the fabric-gateway SDK instead.
 * See: https://hyperledger.github.io/fabric-gateway/
 * ============================================================================
 */

'use strict';

const FabricCAServices = require('fabric-ca-client');
const Client = require('fabric-client');
const { FileSystemWallet, Gateway, X509WalletMixin, } = require('fabric-network');
const fs = require('fs');
const path = require('path');

const ccpPath = path.resolve(__dirname, '..', 'connection.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);

async function main() {
    try {
        const user = 'peer0'
        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = new FileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        const userExists = await wallet.exists(user);
        if (userExists) {
            console.log('An identity for the user already exists in the wallet');
            return;
        }

        // Check to see if we've already enrolled the admin user.
        const adminExists = await wallet.exists('admin');
        if (!adminExists) {
            console.log('An identity for the admin user "admin" does not exist in the wallet');
            console.log('Run the enrollAdmin.js application before retrying');
            return;
        }

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: 'admin', discovery: { enabled: false } });

        // Get the CA client object from the gateway for interacting with the CA.
        // var client = Client.loadFromConfig('fabric-ca-client-config.yaml');
        const ca = gateway.getClient().getCertificateAuthority();
        const adminIdentity = gateway.getCurrentIdentity();
        // Register the user, enroll the user, and import the new identity into the wallet.
        var secret = 'userpw';
        try {
            secret = await ca.register({ affiliation: 'org1.department1', enrollmentID: user, enrollmentSecret: secret, role: 'client', maxEnrollments: -1 }, adminIdentity);
        } catch (error) {

        }
        console.error(`Trying to enroll user`);
        console.log(secret);
        var enrollment = await ca.enroll({ enrollmentID: user, enrollmentSecret: secret });
        const userIdentity = X509WalletMixin.createIdentity('Org1MSP', enrollment.certificate, enrollment.key.toBytes());
        wallet.import(user, userIdentity);
        console.log('Successfully registered and enrolled user and imported it into the wallet');

    } catch (error) {
        console.error(`Failed to register user: ${error}`);
        process.exit(1);
    }
}

main();
