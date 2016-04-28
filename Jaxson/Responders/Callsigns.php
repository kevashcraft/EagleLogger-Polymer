<?php
Namespace Responders;
class Callsigns {

	public static function CallsignInfo() {

		$stm = \Jaxson::$db->prepare("CALL CallsignInfo ( :CallsignID )");
		$stm->execute([':CallsignID' => \Jaxson::$data->CallsignID,]);
		$Callsign = \Jaxson::$db->query("SELECT * FROM _Callsign")->fetch();
		$Callsign['OfficialIDs'] = \Jaxson::$db->query("SELECT * FROM _OfficialIDs")->fetchAll(\PDO::FETCH_COLUMN, 0);
		\Jaxson::$response['Callsign'] = $Callsign;
	}
	

	public static function FCCCallsignInfo() {

		$stm = \Jaxson::$db->prepare("CALL FCCCallsignInfo( :Callsign )");
		$stm->execute([':Callsign' => \Jaxson::$data->Callsign]);
		$Callsign = $stm->fetch();
		if($Callsign) {
			\Jaxson::$response['FCCCallsign'] = $Callsign;
		} else {
			\Jaxson::$response['Error'] = true;
			\Jaxson::$response['toast'] = "Callsign not found in FCC Database";
		}

	}
	

}