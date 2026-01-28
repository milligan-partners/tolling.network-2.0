const schema = require("schm");
const translate = require('schm-translate')
const transaction = require("./transaction.js");
const tagValidation = require("./tagValidation.js");
const correction = require("./correction.js");
const reconciliation = require("./reconciliation.js");

const detailTranslate = translate({
  tvlTagDetails: "TVLTagDetails",
  transactionRecord: "TransactionRecord",
  correctionRecord: "CorrectionRecord",
  reconciliationRecord: "ReconciliationRecord"
});

const transactionSchema = schema({transactionRecord: [transaction.schema]}, detailTranslate);
const correctionSchema = schema({correctionRecord: [correction.schema]}, detailTranslate);
const reconciliationSchema = schema({reconciliationRecord: [reconciliation.schema]}, detailTranslate);
const tagValidationSchema = schema({tvlTagDetails: [tagValidation.schema]}, detailTranslate);

module.exports.transactionSchema = schema({transactionRecord: [transaction.schema]}, detailTranslate);
module.exports.transactionSchema = transactionSchema;
module.exports.tagValidationSchema = tagValidationSchema;
module.exports.correctionSchema = correctionSchema;
module.exports.reconciliationSchema = reconciliationSchema;