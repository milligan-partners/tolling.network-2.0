// transaction.docType = "Transaction";
// transaction.transactionID = staticTransactionAsJSON.totalTransactions + 1;
// transaction.accountID = args[0];
// transaction.hostAgency = args[1];
// transaction.amount = args[2];
// transaction.dateTime = args[3];
// transaction.vehicleClass = args[4]; // possible values: 2,3,4,5,6
// transaction.location = args[5];
// transaction.transactionStatus = args[6];

const schema = require("@iancarv/schm");
const modelFactory = require("./modelFactory.js");

const transactionSchema = schema({
	docType: String,
	transactionID: String,
	accountID: String,
	hostAgency: String,
	amount: String,
	dateTime: String,
	vehicleClass: String,
	location: String,
	transactionStatus: String
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