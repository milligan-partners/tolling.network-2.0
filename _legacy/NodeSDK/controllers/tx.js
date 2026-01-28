'use strict';
const { FileSystemWallet, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');

const ccpPath = path.resolve(__dirname,'..', 'connection.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);
var js2xmlparser = require("js2xmlparser");
const tx = require('../models/tx');

module.exports = {
    parseModel: async(req, res, next) => {
        if (/\/xml$/.test(req.headers['content-type'])) {
            if(req.body) {
                let values = Object.values(req.body);
                req.body = values[0];
                req.body = uncapitalizeKeys(req.body);
            }
        }
        next();
    },
    sendResult: async (req, res, next) => {
        let result = res.locals.result;
        if (/\/xml$/.test(req.headers['content-type'])) {
            res.setHeader('content-type', 'text/xml');
            result = js2xmlparser.parse(res.locals.type, result);
        }
        res.send(result);
    },
    getAccount: async(req, res, next) => {
        res.locals.type = 'GetAccount';
        let accountID = req.params.accountID;
        let tx = ['queryAccount', accountID];
        let result = await sendToBlockchain(tx, 0, req.locals.payload.username);

        res.locals.result = JSON.parse(result);
        next();
    },

    addAccount: async(req, res, next) => {
        let account = req.body;
        res.locals.type = 'AddAccount';
        let tx = [
            'addAccount',
            account.accountID,
            account.lpJurisdiction,
            account.lpNumber,
            account.macAddress,
            account.tagID,
            account.accountStatus
        ];

        account['docType'] = 'account';
        let result = await sendToBlockchain(tx, 1, req.locals.payload.username);
        res.locals.result = {
            result: "OK"
        };
        next();
    },
    changeAccountStatus: async(req, res, next) => {
        let account = req.body;
        res.locals.type = 'ChangeAccountStatus';
        let tx = [
            'changeAccountStatus',
            account.accountID,
            account.accountStatus
        ];

        let result = await sendToBlockchain(tx, 1, req.locals.payload.username);
        res.locals.result = {
            result: "OK"
        };
        next();
    },
    getTransaction: async(req, res, next) => {
        res.locals.type = 'QueryTransaction';
        let transactionId = req.params.transactionId;
        let tx = ['queryTransaction', transactionId];
        let result = await sendToBlockchain(tx, 0, req.locals.payload.username);

        res.locals.result = JSON.parse(result);
        next()
    },
    addTransaction: async(req, res, next) => {
        let transaction = req.body;
        console.log(req.body);
        res.locals.type = 'AddTransaction';
        let tx = [
            'addTransaction',
            transaction.accountID,
            transaction.hostAgency,
            transaction.amount,
            transaction.dateTime,
            transaction.vehicleClass,
            transaction.location,
            transaction.transactionStatus,
        ];

        let result = await sendToBlockchain(tx, 1, req.locals.payload.username);
        res.locals.result = {
            result: "OK"
        };
        next()
    },
    queryTransaction: async(req, res, next) => {
        let hostAgency = req.query.hostAgency;
        res.locals.type = 'QueryTransactionsByHost';
        let tx = ['queryTransactionsByHost', hostAgency];
        let result = await sendToBlockchain(tx, 0, req.locals.payload.username);

        res.locals.result = JSON.parse(result);
        next();
    }
}

async function sendToBlockchain(tx, type, user) {
    console.log(user);
    // Create a new file system based wallet for managing identities.
    const walletPath = path.join(process.cwd(), 'wallet');
    const wallet = new FileSystemWallet(walletPath);
    console.log(`Wallet path: ${walletPath}`);

    // Check to see if we've already enrolled the user.
    const userExists = await wallet.exists(user);
    if (!userExists) {
        console.log('An identity for the user does not exist in the wallet');
        console.log('Run the registerUser.js application before retrying');
        return;
    }

    // Create a new gateway for connecting to our peer node.
    const gateway = new Gateway();
    await gateway.connect(ccp, { wallet, identity: user, discovery: { enabled: false } });
    // Get the network (channel) our contract is deployed to.
    const network = await gateway.getNetwork('channel1');

    // Get the contract from the network.
    const contract = network.getContract('cc');

    if (type == 0) { // Query
        const result = await contract.evaluateTransaction(...tx);
        return result.toString();
    } else { // Transaction
        const result = await contract.submitTransaction(...tx);
        return result.toString();
    }
}

function uncapitalizeKeys(obj) {
    let newObj = {}
    for(var key in obj) {
        let newKey = uncapitalizeFirst(key);
        newObj[newKey] = obj[key];
    }

    return newObj;
}

function uncapitalizeFirst(string) {
    return string.charAt(0).toLowerCase() + string.slice(1);
}