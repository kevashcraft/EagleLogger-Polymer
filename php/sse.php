<?php
	header('Content-Type: text/event-stream');
	header('Cache-Control: no-cache');

	while(true) {
		sleep(1);
		echo "data: " . date('r') . "\n\n";
	}
	// sleep(5);
	// echo "data: " . file_get_contents('lastupdate.id') . "\n\n";
	