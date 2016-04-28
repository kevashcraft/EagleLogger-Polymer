<?php
Namespace Responders;
class Lists {


	public static function ACList() {

		$list = self::ListSwitch(\Jaxson::$data->list);

		$stm = \Jaxson::$db->prepare("CALL $list ( :query, :ACID )");
		$stm->execute([
			':query' => \Jaxson::$data->query,
			':ACID' => \Jaxson::$data->ACID,
		]);

		\Jaxson::$response["ACList"] = $stm->fetchAll();
	}


	public static function ListSwitch($ListName) {
	
		switch ($ListName) {
			case 'Callsigns':
				return 'CallsignsAC';
			case 'CitiesAndCounties':
				return 'CitiesAndCountiesListAC';
		}
	}
	


	
}