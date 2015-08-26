Polymer({
	is: 'el-main',
	behaviors: [
		Polymer.ELBase,
		Polymer.ELRouter,
		Polymer.ELMain
	],
	properties: {
		header: {
			type: String,
			value: ''
		},
		search: {
			type: String,
			value: '',
			observer: '_searchChanged'
		},
		searchHide: {
			type: Boolean,
			value: true
		},
		searchDisabled: {
			type: Boolean,
			value: true
		},
		user: {
			type: Object
		}
	},
	created: function() {
		EL = this;
	},
	ready: function() {
		document.querySelector('#spinner').style.display = 'none';
		if(this.user && this.user.token) this.authed = true;
		this.router();

		// Remove menu anchors default action
		var anchors = this.querySelectorAll('a[data-link]');
		for(a in anchors) {
			anchors[a].onclick = function(event) { event.preventDefault() };
		}
	},
	attached: function() {

		// auto focus inputs and refit dialog
		window.addEventListener('iron-overlay-opened', function(event){
			if(event.target.tagName != 'PAPER-DIALOG') return;
			event.target.fit();
			var fe = event.target.querySelector('[autofocus]');
			if(fe) {
				if(fe.tagName == 'PAPER-INPUT')
					fe.$.input.focus();
				if(fe.tagName == 'INPUT')
					fe.focus();
			}
		});
	},
	about: function() {
		this.$.about.open();
	},
	menuLink: function(event) {
		var page = event.target.dataset.link;
		this.setPage([page]);
	},
	login: function(user) {
		this.user = user;
		this.authed = true;
		this.setPage(['dashboard']);
	},
	logout: function(user) {
		this.user = {};
		this.authed = false;
		if(this.ce.authedRequired) this.setPage(['home']);
	},
	menuHighlighter: function(event) {
	},
	searchDisable: function() {
		this.searchHide = true;
		this.searchDisabled = true;
	},
	searchEnable: function() {
		this.search = '';
		this.searchHide = true;
		this.searchDisabled = false;
	},
	searchShow: function(event) {
		this.search = '';
		this.searchHide = !this.searchHide;
		if(!this.searchHide) {
			this.$.search.$.input.focus();
		}
	},
	_calculateMenu: function(menuItem, user) {
		if(!user) return true;
		if(!user.token) return true;
		switch(menuItem) {
			case 'login':
				return false;
				break;
			case 'logout':
				return false;
				break;
			case 'callsigns':
				return !user.ncs;
				break;
			case 'dashboard':
				return false;
				break;
			default:
				return true;
		}
	},
	_searchChanged: function() {
	},
});
