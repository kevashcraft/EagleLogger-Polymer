<?php

$jaxson = new Jaxson;

class Jaxson
{
	public static $db;
	public static $data;
	public static $response;
	public static $responses = [];
	public static $pool = [];
	public static $SiteToken;

	public function __construct() {

		// Publically Accessible Requests
		$publicRequests = [
			'Events/listener',
			'Site/SitePing',
			'Site/SiteUserNewAccount',
			'Nets/NetsList',
			'Nets/NetTemplatesList',
		];

		// Setup Autoloader
		require 'lib/bootstrap.php';

		// Initialize Database
		self::$db = Tools\Database::connect();

		// Single Request via URL
		if($_SERVER['REQUEST_URI'] != '/Jaxson/') {
			$requestString = str_replace('/Jaxson/', '', $_SERVER['REQUEST_URI']);
			$requestString = substr($requestString, 0, strrpos($requestString, '/'));
			$requestArray = explode('/', $requestString);
			// Check if Publically Available
			if(in_array($requestString, $publicRequests)) {
				// Log Visit
				Tools\Database::logVisit($requestString, 'PUBLIC');
				// Issue Request
				self::requestExecute($requestArray[0],$requestArray[1]);
			} else {
				// Find Token
				$SiteToken =
					isset($_SERVER['HTTP_SITE_TOKEN']) ? $_SERVER['HTTP_SITE_TOKEN'] :
					isset($_POST['SiteToken']) ? $_POST['SiteToken'] :
					isset($_GET['SiteToken']) ? $_GET['SiteToken'] :
					null;
				// Check Token
				if(Tools\Database::logVisit($requestString, $SiteToken)) {
					// Issue Request
					self::requestExecute($requestArray[0],$requestArray[1]);
				} else {
					self::$response['Authorization'] = 'denied';
				}
			}
			// Request via Body
		} else {
			$json = file_get_contents('php://input');
			$body = json_decode($json);
			$SiteToken = $_SERVER['HTTP_SITE_TOKEN'];
			foreach ($body as $index => $data) {
				$requestString = $data->request;
				if(Tools\Database::logVisit($requestString, $SiteToken) || in_array($requestString, $publicRequests)) {
					$requestArray = explode('/', $requestString);
					self::$data = $data;
					self::requestExecute($requestArray[0], $requestArray[1]);
					if(isset(self::$data->Note)) {
						self::$response['Note'] = self::$data->Note;
					}
					self::$responses[] = self::$response;
				} else {
					self::$responses[] = ['Authorization' => 'denied', 'requestString' => $requestString];
				}
			}

		}

		self::respond();
	}

	private function logVisit($requestString, $SiteToken) {

		Tools\Database::logVisit();
	}

	private function requestExecute($Class, $Function) {

		$NamespacedClass = "Responders\\$Class";

		if(method_exists($NamespacedClass, $Function)) {
			self::$response = [ 'request' => $Function ];
			call_user_func([$NamespacedClass, $Function]);
		} else {
			self::$response['errors'][] = "Method does not exist. $Class/$Function";
		}		
	}


	private function respond() {
		array_unshift(self::$responses, [ 'SiteToken' => self::$SiteToken ]);
		echo json_encode(self::$responses);
	}


}