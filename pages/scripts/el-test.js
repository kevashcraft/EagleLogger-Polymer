Polymer({
	is: 'el-test',
	behaviors: [
		Polymer.ELBehavior,
	],
	properties: {
		info: {
			value: function() {
				return {
					title: 'page title'
				}
			}
		},
	},
	listeners: {
		'newo': '_high',
	},
	attached: function() {
			
		if(EL.sseListener) {
			EL.sseListener('teste', 'high', this);
		}

	},
	// _
	_high: function() {
		console.log("i am so");
	},

});