<?php
namespace Responders;
class Site {



	public static function SitePing() {
		\Jaxson::$response['Ping'] = 'Ping';
	}
	

	public static function SiteUserLogin() {

		// get user info per username
		$stm = \Jaxson::$db->prepare("CALL SiteUserPasswordHash ( :Callsign )");
		$stm->execute([":Callsign" => \Jaxson::$data->Callsign]);
		$SiteUser = $stm->fetch();

		// check password
		if($SiteUser && password_verify(\Jaxson::$data->SiteUserPassword, $SiteUser['SiteUserPasswordHash'])) {

				$stm = \Jaxson::$db->prepare("CALL SiteUserLogin ( :SiteUserID )");
				$stm->execute([":SiteUserID" => $SiteUser['SiteUserID']]);
				\Jaxson::$response['Success'] = 1;
				$stm = \Jaxson::$db->prepare("CALL SiteUserInfo ( :SiteUserID )");
				$stm->execute([':SiteUserID' => $SiteUser['SiteUserID']]);
				\Jaxson::$response['SiteUser'] = $stm->fetch();

		} else {
		
			\Jaxson::$response['toast'] = "Invalid credentials";
		}

	}


	public static function SiteUserNewAccount() {

		$Password = randString(64);
		// $EmailAddress = \Jaxson::$data->EmailAddress;
		\Jaxson::$response['Password'] = $Password;
		$PasswordHash = password_hash($Password, PASSWORD_BCRYPT);
		$stm = \Jaxson::$db->prepare("CALL SiteUserNewAccount ( :Callsign, :PasswordHash )");
		$stm->execute([
			':Callsign' => \Jaxson::$data->Callsign,
			':PasswordHash' => $PasswordHash,
		]);
		$Error = \Jaxson::$db->query("SELECT @Error")->fetchColumn();
		if($Error == 'NONE') {
			$Callsign = \Jaxson::$db->query("SELECT @Callsign")->fetchColumn();
			\Tools\EagleMail::NewAccountEmail($EmailAddress, $Callsign, $Password);
			\Jaxson::$response['toast'] = "Account Created! $Callsign Click the link in your email.";
		} else {
			\Jaxson::$response['toast'] = $Error;
		}


	}
	

	public static function SiteUserInfoUpdate() {
		
		$SiteUserPasswordHash = \Jaxson::$data->SiteUserPassword == 'unchangedpassword' ?
			'unchangedpassword' : password_hash(\Jaxson::$data->SiteUserPassword, PASSWORD_BCRYPT);

		$stm = \Jaxson::$db->prepare("CALL SiteUserInfoUpdate (
			:SiteUserID,
			:CallsignName,
			:CallsignRadio,
			:CallsignAntenna,
			:SiteUserPasswordHash
		)");

		$stm->execute([
			':SiteUserID' => \Jaxson::$data->SiteUserID,
			':CallsignName' => \Jaxson::$data->CallsignName,
			':CallsignRadio' => \Jaxson::$data->CallsignRadio,
			':CallsignAntenna' => \Jaxson::$data->CallsignAntenna,
			':SiteUserPasswordHash' => $SiteUserPasswordHash,
		]);
	}
		



	public static function SiteUserPasswordReset() {

		$CellPhoneNumber = preg_replace("/[^0-9]/", '', \Jaxson::$data->CellPhoneNumber);
		$Password = self::SiteUserPasswordGenerate();

		// get the user
		$stm = \Jaxson::$db->prepare("CALL GetSiteUserFromCellPhoneNumber( :CellPhoneNumber ) ");
		$stm->execute([':CellPhoneNumber' => $CellPhoneNumber]);
		$SiteUser = $stm->fetch();

		// reset the password then text the user the new info
		if($SiteUser) {

			// set the password
			$stm = \Jaxson::$db->prepare("CALL SiteUserPasswordSet ( :SiteUserID, :PasswordHash )");
			$stm->execute([
				':SiteUserID' => $SiteUser['SiteUserID'],
				':PasswordHash' => password_hash($Password, PASSWORD_BCRYPT)
			]);

			// text the user
			$message = "Username: " . $SiteUser['SiteUserUsername'] . "\nPassword: $Password";
			\Tools\SinchSMS::SendMessage($CellPhoneNumber, $message);

			\Jaxson::$response['toast'] = 'Check your phone';
		} else {

			\Jaxson::$response['toast'] = 'Number not found..';
		}

	}
	
	public static function SiteUserPasswordSet() {
			$stm = \Jaxson::$db->prepare("CALL SiteUserPasswordSet ( :SiteUserID, :PasswordHash )");
			$stm->execute([
				':SiteUserID' => \Jaxson::$data->SiteUserID,
				':PasswordHash' => password_hash(\Jaxson::$data->SiteUserPassword, PASSWORD_BCRYPT)
			]);
			\Jaxson::$response['toast'] = 'Your password has been set';
	}
	



	public static function SiteUserPasswordGenerate() {
		$charset='ABCDEFGHKMNPQRSTUVWXYZabcdefghkmnpqrstuvwxyz23456789';
		$count = strlen($charset);
		$str = '';
		for ($i=0; $i < 5; $i++) { 
			$str .= $charset[mt_rand(0, $count-1)];
		}

		return $str;

	}
	
	


}