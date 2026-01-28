const schema = require("@iancarv/schm");
const modelFactory = require("./modelFactory.js");

const accountSchema = schema({
	docType: String,
	accountID: String,
	lpJurisdiction: String,
	lpNumber: String,
	macAddress: String,
	tagID: String,
	accountStatus: String
});

const fromXML = function(data) {
	return transactionSchema.parse(data)
}

const convertFn = {
	'xml': fromXML,
	'json': txSchema.parse
}

exports.schema = transactionSchema;
exports.convertFn = convertFn;

modelFactory(exports);