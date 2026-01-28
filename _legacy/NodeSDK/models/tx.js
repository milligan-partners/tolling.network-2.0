const schema = require("@iancarv/schm");
const modelFactory = require("./modelFactory.js");

const txSchema = schema({
  fn: String,
  args: [String],
});

const createModelJson = function(data) {
	return txSchema.parse(data)
};

const createModelXml = function(data) {
	return txSchema.parse(data);
};


const convertFn = {
	'xml': createModelXml,
	'json': createModelJson
};

exports.schema = txSchema;
exports.convertFn = convertFn;

modelFactory(exports);