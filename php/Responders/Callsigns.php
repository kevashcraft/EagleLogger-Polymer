<?php
namespace Responders;
class Callsigns
{

	public static function list_all() {
		$stm = \Jaxson::$db->prepare("SELECT
			callsigns.id, callsigns.callsign, callsigns.name, callsigns.city, callsigns.county, callsigns.ncs, callsigns.jobs
			FROM callsigns
			WHERE valid = 1
			");
		$stm->execute();

		\Jaxson::$response['callsigns'] = $stm->fetchAll();
	}

	public static function list_and_describe()
	{		
		$stm = \Jaxson::$db->prepare("SELECT
			callsigns.id, CONCAT(callsigns.callsign, ' ', callsigns.name, ' ', callsigns.county, ' ', callsigns.city) as callsign
			FROM callsigns
			WHERE valid = 1");

		$stm->execute();

		$returned = $stm->fetchAll(\PDO::FETCH_ASSOC);

		foreach($returned as $callsign) {
			$ids[] = $callsign['id'];
			$callsigns[] = $callsign['callsign'];
		}
		\Jaxson::$response['ids'] = $ids;
		\Jaxson::$response['callsigns'] = $callsigns;
	}

	public static function add_entry()
	{
		$callsign = $_GET['callsign'];
		$name = $_GET['name'];
		$city = $_GET['city'];
		$county = $_GET['county'];
		$jobs = $_GET['jobs'];

		if($county == 'undefined') $county = "";
		if($city == 'undefined') $city = "";

		$stm = \Jaxson::$db->prepare("INSERT INTO callsigns(
			callsign, name, city, county, jobs)
			VALUES(?, ?, ?, ?, ?)
		 ");

		$values = array($callsign, $name, $city, $county, $jobs);
		$stm->execute($values);

		self::list_all();
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

}