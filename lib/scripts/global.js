// EagleLogger Global
var EL;

// hides the spinner and shows the no load error
var error = setTimeout(function(){
	if(typeof EL == 'undefined') {
		document.getElementById('spinner').style.display = 'none';
		document.getElementById('no-load').style.display = 'block';
	}
}, 3000);


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


