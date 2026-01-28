const baseFactory = function(model) {
		return function(args, type) {
			let fn = model.convertFn[type];
			fn = fn? fn: model.schema.parse
			return fn(args);
		}
	}

module.exports = function(model){
		model.factory = baseFactory(model)
	}