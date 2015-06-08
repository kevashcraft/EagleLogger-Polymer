var el;
var ce;
var jaxsons = [];
var netId;
// var sse = new EventSource('/php/sse.php');

function findTarget(e, tag) {
	var target = e.target;
	var tag = tag.toUpperCase();
	while(target.tagName != tag) {
		target = target.parentElement;
	}
	return target;
}

function findTargetByData(e, dialog) {
	var target = e.target;
	while(!target.dataset[dialog]) {
		target = target.parentElement;
	}
	return target;
}


window.addEventListener('iron-overlay-opened', function(event){
	var fe = event.target.querySelector('[autofocus]');
	if(fe) {
		if(fe.tagName == 'PAPER-INPUT')
			fe.$.input.focus();
		if(fe.tagName == 'INPUT')
			fe.focus();
	}
});