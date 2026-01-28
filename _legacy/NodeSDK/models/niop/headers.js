const schema = require("schm");
const translate = require('schm-translate');

const headerTranslate = translate({
  submissionType: "SubmissionType",
  submissionDate: "SubmissionDateTime",
  ssiopHubID: "SSIOPHubID",
  homeAgencyID: "HomeAgencyID",
  awayAgencyID: "AwayAgencyID",
  txnDataSeqNo: "TxnDataSeqNo",
  recordCount: "RecordCount",
  bulkIndicator: "BulkIndicator",
  bulkIdentifier: "BulkIdentifier",
})

const headerSchema = schema({
    submissionType: String,
    submissionDate: Date,
    ssiopHubID: String,
    homeAgencyID: String,
    recordCount: Number,
}, headerTranslate);

const transactionHeaderSchema = schema(
    headerSchema, 
    {
        awayAgencyID: String,
        txnDataSeqNo:Number,
        recordCount:Number,
    },
    previous => previous.merge({
      validators: {
        submissionType: value => ({
          valid: value === "STRAN",
          message: 'Invaid SubmissionType',
        }),
      },
    }
), headerTranslate);

const correctionHeaderSchema = schema(transactionHeaderSchema,
    previous => previous.merge({
      validators: {
        submissionType: value => ({
          valid: value === "SCORR",
          message: 'Invaid SubmissionType',
        }),
      },
    }
), headerTranslate);

const reconciliationHeaderSchema = schema(transactionHeaderSchema,
    previous => previous.merge({
      validators: {
        submissionType: value => ({
          valid: value === "SRECON",
          message: 'Invaid SubmissionType',
        }),
      },
    }
));

const tvlHeaderSchema = schema(headerSchema,
{
    bulkIndicator: String,
    bulkIdentifier: Number,
},previous => previous.merge({
      validators: {
        submissionType: value => ({
          valid: value === "STVL",
          message: 'Invaid SubmissionType',
        }),
      },
    }
), headerTranslate);

exports.schema = headerSchema;
exports.tvlHeaderSchema = tvlHeaderSchema;
exports.transactionHeaderSchema = transactionHeaderSchema;
exports.correctionHeaderSchema = correctionHeaderSchema;
exports.reconciliationHeaderSchema = reconciliationHeaderSchema;