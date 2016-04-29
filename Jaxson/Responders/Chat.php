<?php
namespace Responders;
class Chat {

	public static function ChatMessagesForNet() {
		
		$stm = \Jaxson::$db->prepare("CALL ChatMessagesForNet( :NetID )");
		$stm->execute([
			':NetID' => \Jaxson::$data->NetID,
		]);

		\Jaxson::$response['ChatMessages'] = $stm->fetchAll();
	}
	

	public static function ChatMessageNew() {

		$stm = \Jaxson::$db->prepare("CALL ChatMessageNew( :NetID, :ChatMessage )");
		$stm->execute([
			':NetID' => \Jaxson::$data->NetID,
			':ChatMessage' => \Jaxson::$data->ChatMessage,
		]);

		\Jaxson::$response['ChatMessageID'] = \Jaxson::$db->query("SELECT @ChatMessageID")->fetchColumn();
	}
	




}