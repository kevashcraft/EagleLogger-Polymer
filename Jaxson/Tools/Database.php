<?php
namespace Tools;
class Database {

	private static $db;
	private static $dbuser = 'EagleLogger';
	private static $dbpass = 'EagleLogger';
	private static $dbname = 'EagleLogger';
	private static $dbhost = 'localhost';


	public function connect() {

		self::$db = new \PDO("mysql:host=".self::$dbhost.";dbname=".self::$dbname.";charset=utf8", self::$dbuser, self::$dbpass);
		self::$db->setAttribute(\PDO::ATTR_DEFAULT_FETCH_MODE, \PDO::FETCH_ASSOC);
		return self::$db;
	}


	public static function logVisit($RequestString, $SiteToken) {

		$stm = self::$db->prepare("CALL SiteVisit( :IP, :UserAgent, :SiteToken, :URL)");
		$stm->execute([
			':IP' => $_SERVER['REMOTE_ADDR'],
			':UserAgent' => $_SERVER['HTTP_USER_AGENT'],
			':SiteToken' => $SiteToken,
			':URL' => $RequestString,
		]);

		$ShouldReject = \Jaxson::$db->query("SELECT @ShouldReject")->fetchColumn();
		if($ShouldReject == 'YES') {
			exit();
		}
		$SiteTokenNew = \Jaxson::$db->query("SELECT @SiteToken")->fetchColumn();

		\Jaxson::$SiteToken = $SiteTokenNew;
		return $SiteToken == $SiteTokenNew;
	}


}