<?php
namespace Responders;
class Events
{
	public static function listener() {
		ignore_user_abort(false);

		// Set headers for event stream and no cache
		header('Content-Type: text/event-stream');

		// create listeners array
		$listeners = [];
		// populate it
		foreach ($_GET as $listener => $param) {
			$listeners[$listener] = $param;
		}

		// forever loop, 4th level
		while(1) {

			// checking loop, 3rd level
			while(1) {
				// listener loop, 2nd level
				foreach ($listeners as $listener => $param) {
					// listener switch, 1st level
					switch ($listener) {
						case 'teste':
								unset($listeners[$listener]);
								$listeners['newo'] = "cheddar";
								break 3;
						case 'newo':
								unset($listeners[$listener]);
								break 3;
						case 'none':
							break;
					}
				}

				// send data, ensure connection exists
				echo "\n";
				ob_flush();
				flush();

				// take a lil nappie
				sleep(1);

			}

			// print new data
			echo "data: $listener\n\n";

		}

	}

}