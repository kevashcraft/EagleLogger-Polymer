<?php
Namespace Responders;
class Nets {


	public static function CheckinAdd() {

		$OfficialIDs = array_filter(\Jaxson::$data->OfficialIDs);
		// array_shift($OfficialIDs);
		$OfficialIDsCSL = implode(',', $OfficialIDs);

		$stm = \Jaxson::$db->prepare("CALL CheckinAdd ( :NetID, :CallsignID, :Callsign, :CallsignName, :OfficialIDsCSL, :ZipCodeID )");
		$stm->execute([
			':NetID' => \Jaxson::$data->NetID,
			':CallsignID' => \Jaxson::$data->CallsignID,
			':Callsign' => \Jaxson::$data->Callsign,
			':CallsignName' => \Jaxson::$data->CallsignName,
			':OfficialIDsCSL' => $OfficialIDsCSL,
			':ZipCodeID' => \Jaxson::$data->ZipCodeID,
		]);
		$Error = \Jaxson::$db->query("SELECT @Error")->fetchColumn();
		if($Error != 'NONE') {
			\Jaxson::$response["toast"] = $Error;
		}
	}
	
	public static function CheckinInfo() {
		$stm = \Jaxson::$db->prepare("CALL CheckinInfo ( :CheckinID )");
		$stm->execute([':CheckinID' => \Jaxson::$data->CheckinID,]);
		$Checkin = \Jaxson::$db->query("SELECT * FROM _Checkin")->fetch();
		$Checkin['OfficialIDs'] = \Jaxson::$db->query("SELECT * FROM _OfficialIDs")->fetchAll(\PDO::FETCH_COLUMN, 0);
		\Jaxson::$response['Checkin'] = $Checkin;

	}
	


	public static function CheckinUpdate() {

		$OfficialIDs = array_filter(\Jaxson::$data->OfficialIDs);
		// array_shift($OfficialIDs);
		$OfficialIDsCSL = implode(',', $OfficialIDs);

		\Jaxson::$response['OfficialIDsCSL'] = $OfficialIDsCSL;


		$stm = \Jaxson::$db->prepare("CALL CheckinUpdate ( :CheckinID, :CallsignName, :OfficialIDsCSL, :ZipCodeID, :CheckinIsValid )");
		$stm->execute([
			':CheckinID' => \Jaxson::$data->CheckinID,
			':CallsignName' => \Jaxson::$data->CallsignName,
			':OfficialIDsCSL' => $OfficialIDsCSL,
			':ZipCodeID' => \Jaxson::$data->ZipCodeID,
			':CheckinIsValid' => \Jaxson::$data->CheckinIsValid,
		]);
	}
	

	public static function CheckinsListForNet() {

		$stm = \Jaxson::$db->prepare("CALL CheckinsListForNet ( :NetID )");
		$stm->execute([':NetID' => \Jaxson::$data->NetID]);

		$Checkins = $stm->fetchAll();
		foreach ($Checkins as &$Checkin) {
			$Checkin['OfficialTitles'] = explode(', ', $Checkin['OfficialTitles']);
		}
		\Jaxson::$response['Checkins'] = $Checkins;
	}
	


	public static function NetAdd() {

		$stm = \Jaxson::$db->prepare("CALL NetAdd ( :NetTemplateID, :NetDate, :NetTime )");
		$stm->execute([
			':NetTemplateID' => \Jaxson::$data->NetTemplateID,
			':NetDate' => \Jaxson::$data->NetDate,
			':NetTime' => \Jaxson::$data->NetTime,
		]);

		$stm = false;

		$Error = \Jaxson::$db->query("SELECT @Error")->fetchColumn();

		if($Error == "NONE") {
			\Jaxson::$response['NetURL'] = \Jaxson::$db->query("SELECT @NetURL")->fetchColumn();
		} else {
			\Jaxson::$response['Error'] = true;
			\Jaxson::$response['toast'] = $Error;
		}
	}
	

	public static function NetInfoUpdate() {

		$stm = \Jaxson::$db->prepare("CALL NetInfoUpdate( :NetID, :NetIsActive )");
		$stm->execute([
			':NetID' => \Jaxson::$data->NetID,
			':NetIsActive' => \Jaxson::$data->NetIsActive,
		]);
	}
	


	public static function NetInfo() {

		$stm = \Jaxson::$db->prepare("CALL NetInfo ( :NetID )");
		$stm->execute([
			':NetID' => \Jaxson::$data->NetID,
		]);

		\Jaxson::$response["Net"] = $stm->fetch();
	}
	


	public static function NetInfoFromURL() {

		$stm = \Jaxson::$db->prepare("CALL NetInfoFromURL ( :NetURL )");
		$stm->execute([
			':NetURL' => \Jaxson::$data->NetURL,
		]);

		$Net = $stm->fetch();
		$stm = false;
		\Jaxson::$data->NetID = $Net['NetID'];
		self::CheckinsListForNet();
		\Jaxson::$response["Net"] = $Net;

	}
	


	public static function NetTemplateAdd() {

		$stm = \Jaxson::$db->prepare("CALL NetTemplateAdd (:NetTemplateName, :NetTemplateFrequency, :NetTemplateTime, :NetTypeID)");
		$stm->execute([
			':NetTemplateName' => \Jaxson::$data->NetTemplateName,
			':NetTemplateFrequency' => \Jaxson::$data->NetTemplateFrequency,
			':NetTemplateTime' => \Jaxson::$data->NetTemplateTime,
			':NetTypeID' => \Jaxson::$data->NetTypeID,
		]);

		$stm = false;

		$Error = \Jaxson::$db->query("SELECT @Error")->fetchColumn();

		if($Error === "NONE") {
			\Jaxson::$response['NetTemplateID'] = \Jaxson::$db->query("SELECT @NetTemplateID")->fetchColumn();
			self::NetTemplatesList();
		} else {
			\Jaxson::$response['Error'] = true;
			\Jaxson::$response['toast'] = $Error;
		}
	}


	public static function NetsList() {

		self::NetTemplatesList();
		\Jaxson::$response['NetTypes'] = \Jaxson::$db->query("SELECT * FROM NetTypesList")->fetchAll();
		\Jaxson::$response['Nets'] = \Jaxson::$db->query("SELECT * FROM NetsList")->fetchAll();
	}
	

	public static function NetTemplatesList() {

		\Jaxson::$response['NetTemplates'] = \Jaxson::$db->query("SELECT * FROM NetTemplatesList")->fetchAll();
	}
	

	public static function OfficialsList() {

		\Jaxson::$response['Officials'] = \Jaxson::$db->query("SELECT * FROM OfficialsList")->fetchAll();
	}
	
	

}