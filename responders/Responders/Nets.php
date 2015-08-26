<?php
namespace Responders;
class Nets
{

	public static function list_all() {
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

		\Jaxson::$response['nets'] = $nets;
	}

	public static function add_entry()
	{
		$callsign = $_GET['callsign'];
		$name = $_GET['name'];
		$city = $_GET['city'];
		$county = $_GET['county'];
		$jobs = $_GET['jobs'];

		$stm = \Jaxson::$db->prepare("INSERT INTO callsigns(
			callsign, name, city, county, jobs)
			VALUES(?, ?, ?, ?, ?)
		 ");

		$values = array($callsign, $name, $city, $county, $jobs);
		$stm->execute($values);

		self::list_all();
	}

	public static function retrieve_entry() {
		$net_id = $_GET['net'];
		$ncs = $_GET['ncs'];

		if($net_id == 'new') {
			$stm = \Jaxson::$db->prepare("INSERT INTO nets(
				ndate, start, ncs_id)
				VALUES(NOW(), NOW(), ?)
				");
			$stm->execute(array($ncs));

			$net_id = \Jaxson::$db->lastInsertId();

		}

		$stm = \Jaxson::$db->prepare("SELECT
			nets.id, nets.ndate, nets.start, nets.end, nets.active, (SELECT COUNT(cid) FROM checkins WHERE nid = nets.id) AS checkins, (SELECT COUNT(cid) FROM checkins WHERE nid = nets.id AND traffic = 1) as traffic, nets.ncs_id,  (SELECT CONCAT(callsigns.name, ' (', callsigns.callsign, ')') FROM callsigns WHERE callsigns.id = nets.ncs_id) AS ncs
			FROM nets
			WHERE nets.valid = 1
			AND nets.id = ?
			");
		$stm->execute(array($net_id));

		$net = $stm->fetch();

		$net['dow']	= date('l', strtotime($net['ndate']));
		$net['month']	= date('F', strtotime($net['ndate']));
		$net['day']	= date('jS', strtotime($net['ndate']));
		$net['year']	= date('Y', strtotime($net['ndate']));
		$net['start']	= date('g:i', strtotime($net['start']));
		if($net['active'] != 1)
			$net['end']	= date('g:ia', strtotime($net['end']));

		\Jaxson::$response['net'] = $net;

		$order = $net['active'] == 1 ? 'DESC' : 'ASC';

		$stm = \Jaxson::$db->prepare("SELECT
			checkins.id, checkins.line, checkins.traffic, callsigns.id as cid, callsigns.callsign, callsigns.name, callsigns.city, callsigns.county, callsigns.jobs
			FROM checkins
			LEFT JOIN callsigns ON callsigns.id = checkins.cid
			WHERE checkins.nid = ?
			ORDER BY line $order
			");

		$stm->execute(array($net_id));
		$callsigns = $stm->fetchAll();
		foreach($callsigns as &$callsign) {
			$callsign['traffic'] = $callsign['traffic'] == 1 ? true : false;
		}


		\Jaxson::$response['callsigns'] = $callsigns;
	}

	public static function update_entry()
	{

		$id = $_GET['id'];
		$callsign = $_GET['callsign'];
		$name = $_GET['name'];
		$city = $_GET['city'];
		$county = $_GET['county'];
		$jobs = $_GET['jobs'];

		$stm = \Jaxson::$db->prepare("UPDATE callsigns
			SET	callsign = ?,
			name = ?,
			city = ?,
			county = ?,
			jobs = ?
			WHERE id = ?
		 ");

		$values = array($callsign, $name, $city, $county, $jobs, $id);
		$stm->execute($values);




		self::list_all();
	}


	public static function new_checkin() {
		$net = $_GET['net'];
		$cid = $_GET['cid'];

		$stm = \Jaxson::$db->prepare("INSERT INTO checkins(
				cid,
				nid,
				line
			) SELECT
				:cid,
				:nid,
				(COUNT(cid) + 1)
			FROM checkins WHERE nid = :nid
			");

		$values = array(':nid' => $net, ':cid' => $cid);

		$stm->execute($values);

		self::retrieve_entry();

	}

	public static function add_checkin() {
		$net = $_GET['net'];
		$callsign = $_GET['callsign'];
		$name = $_GET['name'];
		$county = $_GET['county'];
		$city = $_GET['city'];

		if($county == 'undefined') $county = "";
		if($city == 'undefined') $city = "";


		$stm = \Jaxson::$db->prepare("INSERT INTO callsigns
			(callsign, name, county, city)
			VALUES(?, ?, ?, ?)");

		$values = array($callsign, $name, $county, $city);

		$stm->execute($values);

		$cid = \Jaxson::$db->lastInsertId();

		if(!isset($cid) || $cid == 0) return;

		$stm = \Jaxson::$db->prepare("INSERT INTO checkins(
				cid,
				nid,
				line
			) SELECT
				:cid,
				:nid,
				(COUNT(cid) + 1)
			FROM checkins WHERE nid = :nid
			");

		$values = array(':nid' => $net, ':cid' => $cid);

		$stm->execute($values);

		self::retrieve_entry();

	}

	public static function delete_checkin() {
		$net = $_GET['net'];
		$cid = $_GET['cid'];
		$stm = \Jaxson::$db->prepare("UPDATE checkins
			SET line = line - 1
			WHERE id > :cid
			AND nid = :nid
			");
		$values = array(':nid' => $net, ':cid' => $cid);
		$stm->execute($values);

		$stm = \Jaxson::$db->prepare("DELETE FROM checkins WHERE id = ?");
		$stm->execute(array($cid));

		self::retrieve_entry();
	}


	public static function has_traffic() {
		$cid = $_GET['cid'];
		$traffic = $_GET['traffic'];
		$stm = \Jaxson::$db->prepare("UPDATE checkins SET traffic = ? WHERE id = ?");
		$stm->execute(array($traffic, $cid));
	}


	public static function end_net() {
		$net = $_GET['net'];
		$stm = \Jaxson::$db->prepare("UPDATE nets SET end = NOW(), active = 0 WHERE id = ?");
		$stm->execute(array($net));

		self::retrieve_entry();
	}

	public static function reopen_net() {
		$net = $_GET['net'];
		$stm = \Jaxson::$db->prepare("UPDATE nets SET end = NULL, active = 1 WHERE id = ?");
		$stm->execute(array($net));

		self::retrieve_entry();
	}

	public static function delete_net() {
		$net = $_GET['net'];
		$stm = \Jaxson::$db->prepare("UPDATE nets SET valid = 0 WHERE id = ?");
		$stm->execute(array($net));
	}


}