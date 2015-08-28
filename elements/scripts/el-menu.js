Polymer({
	is: 'el-menu',
	properties: {
		authed: {
			type:Boolean,
			value: false
		}
		
	},
	behaviors: [
		Polymer.ELBehaviorBase,
	],
	attached: function() {
		// disable all links to self
		var anchors = this.querySelectorAll('a[href="^/"]');
		for(a in anchors) {
			anchors[a].onclick = function() { event.preventDefault() };
		}

	},
});