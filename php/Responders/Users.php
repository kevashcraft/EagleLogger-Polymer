<?php
namespace Responders;
class Users
{

	public static function login()
	{
		$callsign = $_GET['callsign'];
		$password = $_GET['password'];

		$stm = \Jaxson::$db->prepare("SELECT
			users.id as uid, users.password, callsigns.callsign, callsigns.ncs, callsigns.id as cid
			FROM callsigns
			LEFT JOIN users ON users.cid = callsigns.id
		 	WHERE callsigns.callsign = ?
		 	AND callsigns.valid = 1
		 ");

		$stm->execute(array($callsign));
		$res = $stm->fetch();

		if(!isset($res['uid'])) {
			// echo "no user found";
			$stm = \Jaxson::$db->prepare("SELECT callsigns.id as cid FROM callsigns WHERE callsigns.callsign = ?");
			$stm->execute(array($callsign));
			$res = $stm->fetch();

			if(!isset($res['cid'])) {
				// echo "MAKING CS";
				$stm = \Jaxson::$db->prepare("INSERT INTO callsigns(callsign) VALUES(?)");
				$stm->execute(array($callsign));
				$cid = \Jaxson::$db->lastInsertId();
			} else {
				$cid = $res['cid'];
			}

			$stm = \Jaxson::$db->prepare("INSERT INTO users(cid, password) VALUES(?, ?)");

			$values = array($cid, password_hash($password, PASSWORD_BCRYPT));
			$stm->execute($values);

			$stm = \Jaxson::$db->prepare("SELECT
				users.id as uid, users.password, callsigns.callsign, callsigns.ncs, callsigns.id as cid
				FROM callsigns
				LEFT JOIN users ON users.cid = callsigns.id
			 	WHERE callsigns.callsign = ?
			 	AND callsigns.valid = 1
			 ");

			$stm->execute(array($callsign));
			$res = $stm->fetch();
		}


		$hash = $res['password'];
		$uid = $res['id'];

		if($hash && password_verify($password, $hash)) {
			$token = randString(64);

			$stm = \Jaxson::$db->prepare("INSERT INTO
				tokens(uid, token)
				VALUES(?, ?)
			");

			$values = array($uid, $token);

			$stm->execute($values);

			$ncs = $res['ncs'] == 1 ? true : false;

			\Jaxson::$response['user'] = array(
				'cid' => $res['cid'],
				'uid' => $res['uid'],
				'callsign' => $res['callsign'],
				'password' => 'this is a password',
				'ncs' => $ncs,
				'token' => $token
			);
		} else {
			\Jaxson::$response['toast'] = "Invalid credentials";
		}
	}

	public static function token_check() {
		return true;
	}



	public static function change_password() {
		$uid = $_GET['uid'];
		$password = $_GET['password'];

		$hash = password_hash($password, PASSWORD_BCRYPT);

		$stm = \Jaxson::$db->prepare("UPDATE users SET password = ? WHERE id = ?");

		$stm->execute(array($hash, $uid));

		\Jaxson::$response['toast'] = "Your password has been changed";
	}


}