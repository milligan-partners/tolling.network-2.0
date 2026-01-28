const schema = require("schm");
const { group } = schema;
const headers = require("./headers.js");
const details = require("./details.js");


const translate = require("schm-translate");

const dataTranslate = translate({
	tagValidationList: "TagValidationList",
	transactionData: "TransactionData",
	correctionData: "CorrectionData",
	reconciliationData: "ReconciliationData",
	tvlHeader: "TVLHeader",
	transactionHeader: "TransactionHeader",
	correctionHeader: "CorrectionHeader",
	reconciliationHeader: "ReconciliationHeader",
	tvlDetail: "TVLDetail",
	transactionDetail: "TransactionDetail",
	correctionDetail: "CorrectionDetail",
	reconciliationDetail: "ReconciliationDetail",
});

const dataLookup = {
  "TagValidationList": {
    "tagValidationList": schema({
      tvlHeader: headers.tvlHeaderSchema,
      tvlDetail: details.tagValidationSchema
    }, dataTranslate)
  },
  "TransactionData": {
    transactionData: schema({
      transactionHeader: headers.transactionHeaderSchema,
      transactionDetail: details.transactionSchema
    }, dataTranslate)
  },
  "CorrectionData": {
    "correctionData": schema({
      correctionHeader: headers.correctionHeaderSchema,
      correctionDetail: details.correctionSchema
    }, dataTranslate)
  },
  "ReconciliationData": {
    "reconciliationData": schema({
      reconciliationHeader: headers.reconciliationHeaderSchema,
      reconciliationDetail: details.reconciliationSchema
    }, dataTranslate)
  }
}

const txSchema = function(type) {
	return schema(dataLookup[type], dataTranslate);
};

module.exports = {
	"schema": txSchema,
	factory: function (data) {
    let type = Object.keys(data)[0];
		let sc = txSchema(type);
    sc =  sc.parse(data);
    if (type == "CorrectionData") {
      // console.log(JSON.stringify(data));
      dataCorrs = data.CorrectionData.CorrectionDetail.CorrectionRecord;
      newCorrs = sc.correctionData.correctionDetail.correctionRecord;
      for (let i = 0; i < dataCorrs.length; i++) {
        const corr = dataCorrs[i];
        newCorrs[i].originalTransactionId = corr.OriginalTransactionDetail.TxnReferenceID;
      }
    }
    return sc
	}
}
