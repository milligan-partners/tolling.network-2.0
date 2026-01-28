const schema = require("schm");
const transaction = require("./transaction.js");
const translate = require("schm-translate");

const correctionTranslate = translate({
	recordType:"RecordType",
	correctionTime:"CorrectionDateTime",
	correctionReason:"CorrectionReason",
	resubmitReason:"ResubmitReason",
	otherCorrection:"CorrectionOtherDesc",
	correctionSeqNo:"CorrectionSeqNo",
	resubmitCount:"ResubmitCount",
	homeAgencyTxnRefID:"HomeAgencyTxnRefID",
	// originalTransactionDetail:"OriginalTransactionDetail"
});

const correctionSchema = schema({
  recordType: String,
  correctionTime: Date,
  correctionReason: String,
  resubmitReason: String,
  otherCorrection: String,
  correctionSeqNo: Number,
  resubmitCount: Number,
  homeAgency: String,
  // originalTransaction: transaction.schema,
  originalTransactionId: String
}, correctionTranslate);

exports.schema = correctionSchema;