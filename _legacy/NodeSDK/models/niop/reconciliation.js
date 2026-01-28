const schema = require("schm");
const transaction = require("./transaction.js");
const translate = require("schm-translate");

const reconciliationTranslate = translate({
  txnReferenceID:"TxnReferenceID",
  adjustmentCount:"AdjustmentCount",
  resubmitCount:"ResubmitCount",
  reconHomeAgencyID:"ReconHomeAgencyID",
  homeAgencyTxnRefID:"HomeAgencyTxnRefID",
  postingDisposition:"PostingDisposition",
  discountPlanType:"DiscountPlanType",
  postedAmount:"PostedAmount",
  postedDateTime:"PostedDateTime",
  transFlatFee:"TransFlatFee",
  transPercentFee:"TransPercentFee",
  spare1:"Spare1",
  spare2:"Spare2",
  spare3:"Spare3",
  spare4:"Spare4",
  spare5:"Spare5"
});

const detailTranslate = translate({
  reconciliationDetail: "ReconciliationDetail"
});

const reconciliationSchema = schema({
  txnReferenceID:String,
  adjustmentCount:String,
  resubmitCount:String,
  reconHomeAgencyID:String,
  homeAgencyTxnRefID:String,
  postingDisposition:String,
  discountPlanType:String,
  postedAmount:String,
  postedDateTime:String,
  transFlatFee:String,
  transPercentFee:String,
  spare1:String,
  spare2:String,
  spare3:String,
  spare4:String,
  spare5:String
}, reconciliationTranslate);

module.exports.schema = reconciliationSchema;