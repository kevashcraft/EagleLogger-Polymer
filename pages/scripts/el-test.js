Polymer({
	is: 'el-test',
	behaviors: [
		Polymer.ELBehaviors,
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
			EL.sseListener('newo', false , this);
		}

	},
	// _
	_high: function() {
		console.log("i am so");
	},

});