<?php

$jaxson = new Jaxson;

class Jaxson
{
	public static $db;
	public static $response;

	public function __construct()
	{
		require 'lib/bootstrap.php';

		// Connect to the database
		self::$db = Tools\Database::connect();

		// Parse the URL and set the initial response
		$url = explode('/', parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

		self::$response['subject'] = strtolower($url[2]);
		self::$response['action'] = strtolower($url[3]);


		if(Responders\Users::token_check() || (self::$response['subject'] == 'users' && self::$response['action'] == 'login')) {
			$function = array("Responders\\" . ucfirst(self::$response['subject']), self::$response['action']);
			if(method_exists($function[0], $function[1]))
				call_user_func($function);
			else echo "I'm sorry, dave. " . implode(',', $function);


		}
		self::respond();
	}

	public static function respond() {
		echo json_encode(self::$response);
	}

}