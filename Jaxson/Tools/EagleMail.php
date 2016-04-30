<?php
Namespace Tools;
class EagleMail{

	public static function NewAccountEmail($Callsign, $Token) {
		require 'PHPMailer/PHPMailerAutoload.php';
		
		if(!isset($Callsign)) {
			return;
		}

		$callsign = strtolower($Callsign);

		/**
		 * This example shows settings to use when sending via Google's Gmail servers.
		 */
		//SMTP needs accurate times, and the PHP time zone MUST be set
		//This should be done in your php.ini, but this is how to do it if you don't have access to that
		date_default_timezone_set('Etc/UTC');
		//Create a new PHPMailer instance
		$mail = new \PHPMailer;
		//Tell PHPMailer to use SMTP
		$mail->isSMTP();
		//Enable SMTP debugging
		// 0 = off (for production use)
		// 1 = client messages
		// 2 = client and server messages
		$mail->SMTPDebug = 0;
		//Ask for HTML-friendly debug output
		$mail->Debugoutput = 'html';
		//Set the hostname of the mail server
		$mail->Host = 'smtp.gmail.com';
		// use
		// $mail->Host = gethostbyname('smtp.gmail.com');
		// if your network does not support SMTP over IPv6
		//Set the SMTP port number - 587 for authenticated TLS, a.k.a. RFC4409 SMTP submission
		$mail->Port = 587;
		//Set the encryption system to use - ssl (deprecated) or tls
		$mail->SMTPSecure = 'tls';
		//Whether to use SMTP authentication
		$mail->SMTPAuth = true;
		//Username to use for SMTP authentication - use full email address for gmail
		$mail->Username = "server@kevashcraft.com";
		//Password to use for SMTP authentication
		$mail->Password = "R5QkEHEz6Wz46Adp1FJ4";
		//Set who the message is to be sent from
		$mail->setFrom('server@kevashcraft.com', 'EagleLogger Server');
		//Set an alternative reply-to address
		$mail->addReplyTo('server@kevashcraft.com', 'EagleLogger Server');
		$EmailAddress = "kevin@kevashcraft.com";
		//Set who the message is to be sent to
		// $mail->addAddress("$callsign@arrl.net");
		$mail->addAddress($EmailAddress);
		\Jaxson::$response['EmailAddress'] = $EmailAddress;
		//Set the subject line
		$mail->Subject = 'EagleLogger: New Account';
		//Read an HTML message body from an external file, convert referenced images to embedded,
		//convert HTML into a basic plain-text alternative body
		$mail->msgHTML("
			<h1>Welcome to EagleLogger!</h1>
			<b>$Callsign</b>,	<a href='http://d.eaglelogger.com?NewAccount=true&Callsign=$Callsign&Token=$Token' title='Account Activation'>Click here</a> to activate your account.
			<br><br><br>
			<span>73 de EagleLogger</span>
		");
		// $mail->Body = "Welcome to EagleLogger!This is another email.. please don't block me :/";
		//Replace the plain text body with one created manually
		$mail->AltBody = "Welcome to EagleLogger!\n$Callsign, go to the address below to activate your account.\n\nhttp://d.eaglelogger.com?NewAccount=true&Callsign=$Callsign&Token=$Token\n\n\n73 de EagleLogger";
		//Attach an image file
		// $mail->addAttachment('images/phpmailer_mini.png');
		//send the message, check for errors
		// $mail->send();
		if (!$mail->send()) {
				\Jaxson::$response['MailResult'] = 'Bad!';
		// //     echo "Mailer Error: " . $mail->ErrorInfo;
		} else {
				\Jaxson::$response['MailResult'] = 'GOOD!';
		// //     echo "Message sent!";
		}
	}
	
}
