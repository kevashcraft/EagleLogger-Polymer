Polymer({
	is: 'el-main',
	behaviors: [
		Polymer.ELBehaviorDialog,
		Polymer.ELBehaviorRouter,
		Polymer.ELBehaviorSSE,
	],
	properties: {
		// user info and token, stored in localstorage
		user: Object,
		// loading state - controls spinner
		loading: {
			type: Boolean,
			value: true
		},
		vertMenu: {
			type: Array,
			value: [
				'Login',
				'Help',
			]
		}
	},
	listeners: {
	},
	observers: [
		'dialogFit(userNew)'
	],
	// 
	created: function() {
		// link to global EL variable
		EL = this;

	},
	attached: function() {
		// call the initialization function
		// initializePage();

	},
	// ajax function for entire site
	jaxson: function(url, params, that) {
		// set this
		var that = that || this;
		// Set url
		url = '/jaxson/' + url;

		// create query string
		var param, value, query = [];
		// cycle through parameters
		for(param in params) {
			// grab value
			var value = params[param];
			// grab param
			var param = window.encodeURIComponent(param);
			// set if not null
			if(value != null) {
				// encode
				param += '=' + window.encodeURIComponent(value);
				// push to query array
				query.push(param);
			}
			
		}

		// Add token
		query.push('token=' + this.user.token);

		// Update url
		url += '?' + query.join('&');

		// log url
		console.log("url", url);

		// create request
		var jaxson = document.createElement('iron-request');

		// set promise
		jaxson.completes.then(function(r){
			// grab the response
			var response = r.response;
			// log it
			console.log("response",response);
			// show toast
			if(response.toast)
				EL.toast(response.toast);
			// call that's jaxson
			that._jaxson(response);
		});
		// send the request
		jaxson.send({
			method: 'get',
			handleAs: 'json',
			url: url
		});
	},
	// displays the taoster
	toast: function(message, duration) {
		// grab the toaster
		var toaster = this.$.toast;
		// set the duration
		toaster.duration = duration || 2000;
		// set the text
		toaster.text = message;
		// toast!
		toaster.show();
	},
	userLogin: function(user) {
		// set the user object
		this.user = user;
		// set the authed state
		this.authed = true;
		// go to dashboard
		this.setPage(['dashboard']);
	},
	// log the user out
	userLogout: function() {
		// reset user object
		this.user = { username: this.user.username };
		this.authed = false;
		if(this.ce.authedRequired) this.setPage(['home']);
	},
	// load site after localstorage loaded
	userInit: function() {
		// initialize an empty user
		if(!this.user) {
			// mark first time
			this.firstTime = true;
			this.user = {};
		}

		// mark returning visitor
		this.firstTime = false;

		// set auth boolean
		this.authed = this.user.token != undefined;

		// load the router
		this._router();
	},
	vertMenuAction: function() {
		// get menu
		var menu = event.target;
		// find the action
		var action = this.vertMenu[menu.selected].replace(/ /g, '').toLowerCase();
		// reset menu
		menu.selected = -1;
		// main switch
		switch(action) {
			case 'login':
					this.$$('el-login-dialogs').open();
				break;
			case 'logout':
					this.userLogout();
				break;
		}
	},
	// dialog switch
	_dialog: function(dialog) {
		switch(dialog) {

		}

		this.dialogOpen(dialog);
	},
});