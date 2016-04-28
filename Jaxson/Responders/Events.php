<?php
Namespace Responders;
class Events {
	public static function listener() {

		// Set headers for event stream and no cache
		header("Content-Type: text/event-stream");
		header("Cache-Control: no-cache");
		header("X-Accel-Buffering: no");
		ob_end_clean();

		$EventID = isset($_GET['EventID']) ? $_GET['EventID'] : 0;

		self::EchoEvent("SSEConnectionEstablished", 0);
		$stm = \Jaxson::$db->prepare("SELECT * FROM EventsList WHERE EventID > :EventID");

		$counter = 0;
		while (!connection_aborted()) {

			$stm->execute([':EventID' => $EventID]);
			$events = $stm->fetchAll();
			if(count($events) > 0) {
				foreach ($events as $event) {

					if($event['EventID'] > $EventID) {
						$EventID = $event['EventID'];
						$Event = [
							'EventType' => $event['EventType'],
							'EventData' => $event['EventData'],
						];
						$Event = json_encode($Event);
						self::EchoEvent($Event, $event['EventID']);
					}
					
				}
			} else {
				$counter++;
				if($counter > 5) {
					$counter = 0;
					self::EchoEvent("SSEPing", 0);
				}
			}

  			sleep(1);
		}

	}	


	public static function EchoEvent($Event, $EventID) {
		echo "id: $EventID" . \PHP_EOL;
		echo "event: ServerEvent" . \PHP_EOL;
		echo "data: $Event" . \PHP_EOL;
		echo \PHP_EOL;
		flush();
	}
	


}