window.addEventListener('DOMContentLoaded', function (event) {

	setTimeout(function(){

		if(typeof LogicalApp == 'undefined' || !LogicalApp.IsReady) {

			document.getElementById('loading-error').style.display = 'block';

			setTimeout(function () {
				document.getElementById('loading-emailme').style.display = 'block';
			}, 2000);
		}
	}, 3500);
});