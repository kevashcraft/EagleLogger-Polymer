// EagleLogger Global
var EL;

// hides the spinner and shows the no load error
var error = setTimeout(function(){
	if(typeof EL == 'undefined') {
		document.getElementById('spinner').style.display = 'none';
		document.getElementById('no-load').style.display = 'block';
	}
}, 3000);




function initializePage() {

	// auto focus inputs and refit dialog
	window.addEventListener('iron-overlay-opened', function(){
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
	
}


// returns the target of an event
function findTarget(query, type) {
	var target = event.target;
	var type = type || 'tagName';
	switch(type) {
		case 'tagName':
			var tag = query.toUpperCase();
			while(target && target.tagName != tag) {
				target = target.parentElement;
			}
			return target;
	}
}
