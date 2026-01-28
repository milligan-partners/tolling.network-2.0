'use strict';
const { FileSystemWallet, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');

const ccpPath = path.resolve(__dirname,'..', 'connection.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);

const tx = require('../models/niop/tx.js');

module.exports = {
    parseModel: async(req, res, next) => {
        let type = 'json'
        if (/\/xml$/.test(req.headers['content-type'])) {
            type = 'xml'
        }

        req.body = tx.factory(req.body);
        next();
    },
    handleTx: async (req, res, next) => {
        if (/\/xml$/.test(req.headers['content-type'])) {
            res.setHeader('content-type', 'text/xml');
            let key = Object.keys(req.body)[0];
            console.log(JSON.stringify(req.body[key]));
            let templates = {
                "tagValidationList": 'xml/tag_validation',
                "transactionData": 'xml/transaction',
                "correctionData": 'xml/correction',
                "reconciliationData": 'xml/reconciliation',
            };

            res.render(templates[key], { data: req.body[key] });
        }
    },
}