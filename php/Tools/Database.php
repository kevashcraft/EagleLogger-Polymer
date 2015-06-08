<?php
namespace Tools;
class database
{
	private static $db;
	private static $dbuser = 'elncs';
	private static $dbpass = 'I am KM4FPA';
	private static $dbname = 'eaglelogger';
	private static $dbhost = 'localhost';

	public static function connect() {
		try {
			self::$db = new \PDO("mysql:host=".self::$dbhost.";dbname=".self::$dbname, self::$dbuser, self::$dbpass);
			self::$db->setAttribute(\PDO::ATTR_DEFAULT_FETCH_MODE, \PDO::FETCH_ASSOC);
		} catch(PDOException $e) {
			echo $e->getMessage();
		}
		return self::$db;
	}
}