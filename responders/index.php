<?php

$jaxson = new Jaxson;

class Jaxson
{
	public static $db;
	public static $response;
	public static $unauthed;

	public function __construct()
	{
		require 'lib/bootstrap.php';

		self::$db = Tools\Database::connect();

		$url = explode('/', parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

		$subject = self::$response['subject'] = strtolower($url[2]);
		$action = self::$response['action'] = strtolower($url[3]);
		$unauthed = self::$unauthed = [
			'events' => [
				'listener',
			],
			'nets' => [
				'list_all',
				'retrieve_entry',
			],
			'users' => [
				'login',
			],
		];

		if(in_array($action, $unauthed[$subject])) {
			self::$response['unauthed'] = true;
			$goodtogo = true;
		} elseif (Responders\Users::token_check()) {
			$goodtogo = true;
		}

		if($goodtogo) {
			$function = array("Responders\\" . ucfirst($subject), $action);
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