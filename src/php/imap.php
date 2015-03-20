<?php
	include_once "classes/class_HeliumAuthenticator.php";
	include_once "classes/class_IMAPBoxChecker.php";
	include_once "classes/class_IMAPAttachment.php";

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
		
		if('checkIMAP'==$action)
		{
			/**
			*	Get new messages that are not in the uploaded list "msgIDs"
			*	Get the current location of each message in msgIDs, returning a "moved to" structure for any that have moved
			*/
			$imap_username = $vals['imap_username'];
			$imap_password = $vals['imap_password'];
			$imap_server = $vals['imap_server'];
			$imap_port = $vals['imap_port'];
			$imap_encrypt = $vals['imap_encrypt'] ? 'ssl' : ''; 

			$checkBoxes = $vals['checkBoxes'];
			
			$unfound = $vals['msgIDs'] ? $vals['msgIDs'] : array();
			
			//find out where everything is
			$found = array();
			$moved = array();
			$news = array();
			foreach($checkBoxes as $mailboxName => $mailbox){
				//connect to the box
				$boxName = $mailbox['mailbox'];
				$boxID = $mailbox['boxID'];
				$imapCheck = new IMAPBoxChecker($imap_username, $imap_password, $imap_server, $imap_port, $imap_encrypt, $boxName );	
				$ms = $imapCheck->getBoxMessageStata($unfound); //found, moved, unaccounted, new
				$found[$boxName] = array('msgs'=>$ms['found'], 'mailbox'=>$mailbox);
				$moved[$boxName] = array('msgs'=>$ms['moved'], 'mailbox'=>$mailbox);
				$news[$boxName] = array('msgs'=>$ms['news'], 'mailbox'=>$mailbox);
				$unfound = $ms['unfound'];
			}
			//now every message in every box has been tested
			
			$res['msgs'] = array('moved'=>$moved,'news'=>$news,'unfound'=>$unfound);
			
			$res['profileGUID'] = $vals['profileGUID']; //roundtrip info
			$res['res'] = 'success';


		}
		else if('getIMAPAttachment'==$action)
		{
	
			$imap_username = $vals['imap_username'];
			$imap_password = $vals['imap_password'];
			$imap_server = $vals['imap_server'];
			$imap_port = $vals['imap_port'];
			$imap_encrypt = $vals['imap_encrypt'] ? 'ssl' : ''; 
			$imap_box = $vals['imap_box'];
			$messageID = $vals['message_id'];
			$fpos = $vals['fpos'];
						
			$imapAttachment = new IMAPAttachment($imap_username, $imap_password, $imap_server, $imap_port, $imap_encrypt, $imap_box, $messageID, $fpos );
			$res['data'] 			= $imapAttachment->getData();
			$res['res'] 			= 'success';
			$res['imap_boxID'] 		= $vals['imap_boxID'];
			$res['imap_box'] 		= $vals['imap_box'];
			$res['profileGUID'] 		= $vals['profileGUID'];
			$res['attachmentGUID']	= $vals['attachmentGUID'];
			$res['filetype']		= $vals['filetype'];

		}
		else if('moveGroupedMessages'==$action)
		{
			/**
			*	groupedMessages:[<profileGUID>:{profileGUID, imap_username, imap_password, imap_server, imap_port, imap_encrypt
			*	, messages:[mailMessageGUID, messageID, lastMailboxName, targetMailboxName ]} ]
			*/
				
			$groupedMessages = $vals["groupedMessages"];
			foreach($groupedMessages as $profileGUID => $moveSet){
				$imap_username = $moveSet['imap_username'];
				$imap_password = $moveSet['imap_password'];
				$imap_server = $moveSet['imap_server'];
				$imap_port = $moveSet['imap_port'];
				$imap_encrypt = $moveSet['imap_encrypt'] ? 'ssl' : ''; 
				
				$msMsgs = $moveSet["messages"];
				$msgCount = count($msMsgs);
				for($msgi=0;$msgi<$msgCount;$msgi++){
					$msg = $msMsgs[$msgi];
					$lastMailboxName = $msg["lastMailboxName"];
					$messageID = $msg["messageID"];
					$targetMailboxName = $msg["targetMailboxName"];
					$imapCheck = new IMAPBoxChecker($imap_username, $imap_password, $imap_server, $imap_port, $imap_encrypt, $lastMailboxName );
					$imapCheck->moveMessage( $messageID, $targetMailboxName );			
				}
				
			}
			
			
			$res = $vals;			
		}
		//last action
	}
	//end of validated

	exit( json_encode($res) );
	
/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

function isValid($userGUID, $pass)
{
	$Auth = new HeliumAuthenticator($userGUID);
	
	return $Auth->authenticate($pass);

}


?>