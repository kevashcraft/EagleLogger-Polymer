<?php
namespace Responders;
class Events
{

	public static function net_listener()
	{
		header('Content-Type: text/event-stream');
		header('Cache-Control: no-cache');
		$id = $_SERVER['HTTP_LAST_EVENT_ID'];
		$net = $_GET['net'];

		while(true) {

			sleep(2);

			$stm = \Jaxson::$db->prepare("SELECT			
				checkins.id,  (SELECT nets.active FROM nets WHERE nets.id = :nid) AS active
				FROM checkins
				WHERE checkins.nid = :nid
				ORDER BY id DESC
				LIMIT 1
				");

			$values = array(':nid' => $net);

			$stm->execute($values);

			$test = $stm->fetch();


			if(isset($test['id']) && ( $test['id'] > $id || $test['active'] != 1 )) break;

		}

		$order = $test['active'] == 1 ? 'DESC' : 'ASC';

		$stm = \Jaxson::$db->prepare("SELECT
			checkins.id, checkins.line, checkins.traffic, callsigns.id as cid, callsigns.callsign, callsigns.name, callsigns.city, callsigns.county, callsigns.jobs
			FROM checkins
			LEFT JOIN callsigns ON callsigns.id = checkins.cid
			WHERE checkins.nid = :nid
			ORDER BY line $order
			");

		$stm->execute($values);

		$checkins = $stm->fetchAll();

		foreach($checkins as &$checkin) {
			$checkin['traffic'] = $checkin['traffic'] == 1 ? true : false;
		}
		
		$event = $test['active'] == 1 ? 'checkin' : 'final';

		$id = $test['id'];
		echo "id: $id\n";
		echo "event: $event\n";
		echo "data: ".json_encode($checkins)."\n\n";
	}



	public static function nets_listener()
	{
		header('Content-Type: text/event-stream');
		header('Cache-Control: no-cache');
		$id = $_SERVER['HTTP_LAST_EVENT_ID'];

		if(!isset($id)) {
			$id = $_GET['net'];
			$active = $_GET['active'] == true ? 1 : 0;
		} else {
			$active = substr($id, -1) == 'a' ? 1 : 0;
			$id = substr($id, 0, strlen($id) - 1);
		}

		while(true) {

			$stm = \Jaxson::$db->prepare("SELECT
				nets.id, nets.active
				FROM nets
				WHERE nets.valid = 1
				ORDER BY nets.id DESC
				LIMIT 1
				");
			$stm->execute();

			$net = $stm->fetch();

			if($net['id'] > $id || $net['active'] != $active) 
				break;

			sleep(2);
		}

		$stm = \Jaxson::$db->prepare("SELECT
			nets.id, nets.ndate, nets.start, nets.end, nets.active, (SELECT COUNT(cid) FROM checkins WHERE nid = nets.id) AS checkins, (SELECT COUNT(cid) FROM checkins WHERE nid = nets.id AND traffic = 1) as traffic, (SELECT CONCAT(callsigns.name, ' (', callsigns.callsign, ')') FROM callsigns WHERE callsigns.id = nets.ncs_id) AS ncs
			FROM nets
			WHERE nets.valid = 1
			ORDER BY nets.id DESC
			");
		$stm->execute();

		$nets = $stm->fetchAll();

		foreach($nets as &$net) {
			$net['dow']	= date('l', strtotime($net['ndate']));
			$net['month']	= date('F', strtotime($net['ndate']));
			$net['day']	= date('jS', strtotime($net['ndate']));
			$net['year']	= date('Y', strtotime($net['ndate']));
			$net['start']	= date('g:i', strtotime($net['start']));
			$net['active'] = $net['active'] == 1 ? true : false;
			if(!$net['active'])
				$net['end']	= date('g:ia', strtotime($net['end']));
		}

		$active = $nets[0]['active'] == 1 ? 'a' : 'i';
		$id = $nets[0]['id'] . $active;
		echo "id: $id\n";
		echo "event: nets\n";
		echo "data: " . json_encode($nets) . "\n\n";

	}

}