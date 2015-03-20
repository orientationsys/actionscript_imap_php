<?php
	//include_once "classes/class_HeliumAuthenticator.php";
	include_once 'classes/class_ExchangeWebDAV.php';
	
	header('Cache-Control: no-cache, must-revalidate');
	header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
//	header('Content-type: text/json');

//	error_reporting(-1);
	$vals = json_decode(stripslashes($_REQUEST["jsn"]),true); //parse the POST data for whatever

	$action = $vals['action'];
	
	$res = array(); //holds results and is returned
	$res['res'] = 'FAIL';
	$res['action'] = $action;

	//gzip
	ob_start("ob_gzhandler");

		//collect the values
	$userGUID = $vals['userGUID'];
	$pass = $vals['pass'];
			
	//valid user?
	if( !isValid($userGUID, $pass) ) //not valid
	{
		$res['res'] = 'notauth';
		$res['warn'] = 'something wrong:' . $action;
	}
	else //valid
	{
		$res['res'] = 'authorized';
		
		
		if('testCredentials'==$action)
		{
			
			$exch_username = $vals['exch_username'];
			$exch_password = $vals['exch_password'];
			$exch_domain = $vals['exch_domain'];
			$exch_mailbox = $vals['exch_mailbox'] ? $vals['exch_mailbox'] : $vals['exch_username'];
			$exch_authdest = $vals['exch_authdest'] ? $vals['exch_authdest'] : $vals['exch_server'];
			$exch_server = $vals['exch_server'];
			$exch_protocol = $vals['exch_protocol'];
			$exch_version = $vals['exch_version'];
			$exch_box = $vals['exch_box'];

			$exchDAV = new ExchangeWebDAV($exch_username, $exch_password, $exch_domain, $exch_mailbox, $exch_authdest, $exch_server, $exch_protocol, $exch_version, $exch_box);
		
			$res['res'] = $exchDAV->testCredentials();
			

		}
		
		
		else if('checkExchange'==$action)
		{
			$exch_username = $vals['exch_username'];
			$exch_password = $vals['exch_password'];
			$exch_domain = $vals['exch_domain'];
			$exch_mailbox = $vals['exch_mailbox'] ? $vals['exch_mailbox'] : $vals['exch_username'];
			$exch_authdest = $vals['exch_authdest'] ? $vals['exch_authdest'] : $vals['exch_server'];
			$exch_server = $vals['exch_server'];
			$exch_protocol = $vals['exch_protocol'];
			$exch_version = $vals['exch_version'];
			$exch_box = $vals['exch_box'];
			$folderAndFile = $vals['folderAndFile'];
			$ignoreMsgIDs = $vals['msgIDs'] ? $vals['msgIDs'] : array();
			$dbMsgIDs = $vals['dbMsgIDs'] ? $vals['dbMsgIDs'] : array();

			$exchDAV = new ExchangeWebDAV($exch_username, $exch_password, $exch_domain, $exch_mailbox, $exch_authdest, $exch_server, $exch_protocol, $exch_version, $exch_box);
		
			$exchDAV->open();
	
			$res['msgs'] = $exchDAV->getBoxMessagesExcept( $ignoreMsgIDs );
			$res['res'] = 'success';
			$res['exch_boxID'] = $vals['exch_boxID'];
			$res['exch_box'] = $vals['exch_box'];
			$res['profileGUID'] = $vals['profileGUID'];
			//$res['delMsgIds'] = $exchDAV->getDelMsgIds( $dbMsgIDs );

		}
		else if('getExchangeAttachment'==$action)
		{
		
			$exch_username = $vals['exch_username'];
			$exch_password = $vals['exch_password'];
			$exch_domain = $vals['exch_domain'];
			$exch_mailbox = $vals['exch_mailbox'] ? $vals['exch_mailbox'] : $vals['exch_username'];
			$exch_authdest = $vals['exch_authdest'] ? $vals['exch_authdest'] : $vals['exch_server'];
			$exch_server = $vals['exch_server'];
			$exch_protocol = $vals['exch_protocol'];
			$exch_version = $vals['exch_version'];
			$exch_box = $vals['exch_box'];
			$folderAndFile = $vals['folderAndFile'];
	
			$exchDAV = new ExchangeWebDAV($exch_username, $exch_password, $exch_domain, $exch_mailbox, $exch_authdest, $exch_server, $exch_protocol, $exch_version, $exch_box);
	
			$exchDAV->open();
	
			$res['data'] 			= $exchDAV->getAttachment($folderAndFile);
			$res['res'] 			= 'success';
			$res['exch_boxID'] 		= $vals['exch_boxID'];
			$res['exch_box'] 		= $vals['exch_box'];
			$res['profileGUID'] 		= $vals['profileGUID'];
			$res['attachmentGUID']	= $vals['attachmentGUID'];
			$res['filetype']	= $vals['filetype'];

		}
		else if('moveExchangeMessage'==$action)
		{
		
			$exch_username = $vals['exch_username'];
			$exch_password = $vals['exch_password'];
			$exch_domain = $vals['exch_domain'];
			$exch_mailbox = $vals['exch_mailbox'] ? $vals['exch_mailbox'] : $vals['exch_username'];
			$exch_authdest = $vals['exch_authdest'] ? $vals['exch_authdest'] : $vals['exch_server'];
			$exch_server = $vals['exch_server'];
			$exch_protocol = $vals['exch_protocol'];
			$exch_version = $vals['exch_version'];
			$exch_box = $vals['exch_box'];
			$targetURI = $vals['targetURI'];
			$destinationURI = $vals['destinationURI'];
			$subjects = $vals['subjects'] ? $vals['subjects'] : array();			
			$res = $vals;
			
			$exchDAV = new ExchangeWebDAV($exch_username, $exch_password, $exch_domain, $exch_mailbox, $exch_authdest, $exch_server, $exch_protocol, $exch_version, $exch_box);
	
			$exchDAV->open();
			
			$res['data'] = $exchDAV->moveMessage($subjects, $targetURI, $destinationURI);
			
			$res['res'] = 'success';
			
		}			
		//last action
	}
	//end of validated

	exit( json_encode($res) );
	
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

function isValid($userGUID, $pass)
{
/*	$Auth = new HeliumAuthenticator($userGUID);
	
	return $Auth->authenticate($pass);*/
	return true;
}

function sendMsg($sendToAddress, $subject, $message, $blHTML){
	$headers = 'From: Robot Blimp Inc. Verification <verify@robotblimp.com>' . "\r\n" .
		'Reply-To: Robot Blimp Inc. Verification <verify@robotblimp.com>' . "\r\n";
	
	if($blHTML){
		$headers .=	'Content-type: text/html' . "\r\n";
	}
//		'X-Mailer: PHP/' . phpversion();
	$sendmail_args  = '-fverify@robotblimp.com';

	ini_set('sendmail_from','verify@robotblimp.com');
	mail($sendToAddress, $subject, $message, $headers,$sendmail_args );
}

?>