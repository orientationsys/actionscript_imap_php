<?php
/**
*	RBI Helium
*
*	Central IMAP 
*
*	Andrew Horst
*
*/

/**
*	Device request to central server
*	-credentials, action, optional known IDs
*
*	Server IMAP connection
*
*	Server compare IDs
*
*	Server returns unmatched ID messages to Device
*
*	Server retains nothing.
*
**/

//Called from lift.php


class IMAPBoxChecker {
	
	private	$username;
	private $password;
	private $connectStr;
	private $box;
	private $imapStream;
	
	function __construct($pUsername, $pPassword, $pServer, $pPort, $pEncrypt, $pBox ){
		$this->username = $pUsername;
		$this->password = $pPassword;
		$this->connectStr = '{' . $pServer . ':' . $pPort . '/imap/novalidate-cert/' . $pEncrypt . '}' . $pBox;
		$this->box = $pBox;		
//		HttpResponse::setGzip  ( true);

	}

	public function getBoxMessageStata( $messageIDs ){
	
		$connectError = $this->connect();
		if(!$this->imapStream){
			// 'Could not connect: ' . $connectError;
			return;
		}
		

		/*
		* get an object having:	etc.
		*	Nmsgs - number of messages in the mailbox
		*/
		
		$boxSummary = imap_check($this->imapStream); 
		
		//get an array of message overview objects
		//	having etc. subject, from, to, message_id
		$msgOverviews = imap_fetch_overview($this->imapStream, "1:{$boxSummary->Nmsgs}",0);
		//$msgOverviews = imap_fetch_overview($this->imapStream, "1:5",0);
		
		
		/**
		*	Compare the message overviews in this box to the list of messages we have
		*	If an overview is not in the have-list, download the message
		*	If an overview is in the list AND the list-entry is for this box, return FOUNDIN:Box
		*	If an overview is in the list AND the list-entry is NOT for this box, return MOVEDTO:Box
		*/
		
		$unseenMsgs = array();
		$foundMessages = array();
		$movedMessages = array();
		$unaccountedMessages = array();
		$matched = false;
//		error_log('testing ' . count($msgOverviews) . ' message overviews in ' . $this->box);
		foreach($msgOverviews as $msgOvv){
			$matched = false;
			$msgCount = count($messageIDs);
			
			//look for a match with one of the messages we have
		//	error_log('test against ' . $msgCount . 'messages');
			for($msgi=0;$msgi<$msgCount;$msgi++){
				$msg = $messageIDs[$msgi];
				
		//		error_log('testing ' . json_encode($msgOvv));
		//		error_log('against ' . json_encode($msg) );
				
				if(	$msgOvv->message_id == $msg['messageID'] ){ //it's in this box
					$matched = true;
					if($this->box == $msg['lastMailboxName']){ //this is the box the device thinks it's in; record FOUND
						array_push($foundMessages, $msg);
				//		error_log('matched and FOUND');
					}
					else{ //moved
						array_push($movedMessages, $msg);
				//		error_log('matched and MOVED');
					}
					break;
				}
			}
			
			
			if(!$matched){
				try{
					array_push($unseenMsgs, $msgOvv);
				}
				catch(Exception $e){
					error_log($e);
//					error_log(var_dump($msgOvv));	
				}
			}
		}
		
		//what messages were sent in but not matched?
		$unfound = array();
		$mc = count($messageIDs);
		$foundAndMoved = array_merge($foundMessages, $movedMessages);
//		error_log('foundAndMoved ' . json_encode($foundAndMoved) );
		foreach($messageIDs as $msg){
			$match = false;
			foreach($foundAndMoved as $fam){
				if(	$fam['messageID'] == $msg['messageID']){
					$match = true;	
				}
			}
			if(!$match){
				array_push($unfound, $msg);	
			}
		}
		
//		error_log('unfound ' . json_encode($unfound));
		
		$resultMessages = array('found'=>$foundMessages,'moved'=>$movedMessages,'unfound'=>$unfound,'news'=>array() );
		
		//request all unseen messages
		foreach($unseenMsgs as $uMsg){
			$msgBundle = array('head'=>$uMsg, 'parts'=>array());
			
			$msgBundle['parts'] = $this->getData($this->imapStream, $uMsg->msgno);
			$resultMessages['news'][$uMsg->message_id] = $msgBundle;
		}
		
		
		//$resultMessages = $this->getdata($this->imapStream);
		
		//disconnect!
		$this->close();
		
		//return
		return $resultMessages;
		
	}
	
	private function close(){
		imap_close($this->imapStream);
	}
	
	private function connect(){
		try{
			$this->imapStream = imap_open($this->connectStr, $this->username, $this->password);
		}
		catch(Exception $e){
			error_log('IMAP connect error: ' . $e);
		}
		return imap_last_error();
	}
	
	
	
	private function OLDgetpart($mbox,$mid,$p,$partno) {
		//http://us.php.net/manual/en/function.imap-fetchstructure.php#85685
		// $partno = '1', '2', '2.1', '2.1.3', etc if multipart, 0 if not multipart
	
		$msg = array('html'=>'','plain'=>'','attachments'=>array());
		
		// DECODE DATA
		$data = ($partno)?
			imap_fetchbody($mbox,$mid,$partno):  // multipart
			imap_body($mbox,$mid);  // not multipart
			
		// Any part may be encoded, even plain text messages, so check everything.
		if ($p->encoding==4)
		{
			$data = quoted_printable_decode($data);
		}
		elseif ($p->encoding==3)
		{
			$data = base64_decode($data);
		}
		// no need to decode 7-bit, 8-bit, or binary
	
	//part type
	//0	text, 1	multipart, 2 message, 3 application, 4 audio, 5 image, 6 video, 7 other
	
		// PARAMETERS
		// get all parameters, like charset, filenames of attachments, etc.
		$params = array();
		if ($p->parameters)
		{
			foreach ($p->parameters as $x)
			{
				$params[ strtolower( $x->attribute ) ] = $x->value;
			}
		}
		if ($p->dparameters)
		{
			foreach ($p->dparameters as $x)
			{
				$params[ strtolower( $x->attribute ) ] = $x->value;
			}
		}
	
	/*
		// ATTACHMENT
		// Any part with a filename is an attachment,
		// so an attached text file (type 0) is not mistaken as the message.
		if ($params['filename'] || $params['name']) {
			// filename may be given as 'Filename' or 'Name' or both
			$filename = ($params['filename'])? $params['filename'] : $params['name'];
			// filename may be encoded, so see imap_mime_header_decode()
			$msg['attachments'][$filename] = $data;  // this is a problem if two files have same name
		}
	*/
		// TEXT
		elseif ($p->type==0 && $data) {
			// Messages may be split in different parts because of inline attachments,
			// so append parts together with blank row.
			$charset = $params['charset'];  // assume all parts are same charset
			$data = iconv($charset,"UTF-8",$data);
			
			if (strtolower($p->subtype)=='plain')
				$msg['plain'] .= trim($data) ."\n\n";
			else
				$msg['html'] .= $data ."<br><br>";

		}
	
		// MULTIPART/ALTERNATIVE : TEXT and HTML
		elseif ($p->type==1 && $data) {
				
		}
		// EMBEDDED MESSAGE
		// Many bounce notifications embed the original message as type 2,
		// but AOL uses type 1 (multipart), which is not handled here.
		// There are no PHP functions to parse embedded messages,
		// so this just appends the raw source to the main message.
		elseif ($p->type==2 && $data) {
			$msg['plain'] .= trim($data) ."\n\n";
		}
		
		// SUBPART RECURSION
		if ($p->parts) {
			foreach ($p->parts as $partno0=>$p2)
			{
			// getpart($mbox,$mid,$p,$partno) {
				$subMsg = $this->getpart($mbox,$mid,$p2,$partno.'.'.($partno0+1));  // 1.2, 1.2.1, etc.
				$msg['plain'] .= $subMsg['plain'];
				$msg['html'] .= $subMsg['html'];
			//	$msg['attachments'] = array_merge($msg['attachments'],$subMsg['attachments']);
			}
		}
		
		return $msg;
	}
	
	private function getpart($mbox,$msgNo,$part,$i) 
	{
		$message = array('plain'=>'','html'=>'','attachments'=>array(), 'subparts'=>array());
		
		if($part->subtype == 'PLAIN') {
			$data = imap_fetchbody($mbox, $msgNo, $i);
		}
		else{
			$data = imap_fetchbody($mbox, $msgNo, "1");					
			//$data = imap_fetchbody($mbox, $msgNo, $i+1 . ".1.2");
		}


	// Any part may be encoded, even plain text messages, so check everything.
		if ($part->encoding==4)
		{
			$data = quoted_printable_decode($data);
		}
		else if ($part->encoding==3)
		{
			$data = base64_decode($data);
		}

/*			$message['partTypes'][$i] = array('type'=>$part->type,'hasData'=>empty($data),'subType'=>$part->subtype
										, 'encoding'=>$part->encoding, 'disposition'=>$part->disposition
										, 'params'=>$part->parameters, 'rawData'=>$data);
*/
		if ($part->type==0) {
			// Messages may be split in different parts because of inline attachments,
			// so append parts together with blank row.
			if (strtolower($part->subtype)=='plain')
			{
				$message['plain'] .= trim($data) ."\n\n";
			}
			else
			{
				//possibly convert charset
				if($part->ifparameters)
				{
					foreach($part->parameters as $param)
					{
						if(strtoupper($param->attribute)=="CHARSET")
						{
							$data = iconv($param->value, "UTF-8",$data);
							break;
						}
					}
				}
				$message['html'] .= $data ."<br><br>";
			}

//				$charset = $params['charset'];  // assume all parts are same charset
		}
	
		// MULTIPART/ALTERNATIVE : TEXT and HTML
		else if ($part->type==1 && $data) {
			//nothing??	
		}
		// EMBEDDED MESSAGE
		// Many bounce notifications embed the original message as type 2,
		// but AOL uses type 1 (multipart), which is not handled here.
		// There are no PHP functions to parse embedded messages,
		// so this just appends the raw source to the main message.
		else if ($part->type==2 && $data) {
			$message['plain'] .= trim($data) ."\n\n";
		}

		// ATTACHMENTS
		if($part->disposition == "ATTACHMENT" || $part->disposition == 'inline') {
			$attachment = array();
			$attachment['type'] = $enum["attachment"]["type"][$part->type] . "/" . strtolower($part->subtype);
			$attachment["subtype"] = strtolower($part->subtype);
			$attachment['ext']=$part->subtype;
			$attachment['byteCount']=$part->bytes;

			$pn=0;
			while($part->dparameters[$pn])
			{
				if($part->dparameters[$pn]->attribute=='FILENAME')
				{
					$attachment['filename']=$part->dparameters[$pn]->value;
					break;
				}
				$pn++;
			}
			
			
		//	$mege = imap_fetchbody($mbox,$msgNo,$fpos);  //we don't dl the data until the user actually asks for it
			
			$attachment['fpos'] = $fpos;
			$attachment['data'] = '';//$mege;
				
			//$data=$this->getdecodevalue($mege,$part->type);	
			
			array_push($message['attachments'],$attachment);
			
			$fpos+=1;
		}
		
		if ($part->parts) {
			foreach ($part->parts as $partno0=>$p2){
				//array_push($message['subparts'], $this->getpart($mbox,$msgNo,$p2,($i+1).'.'.($partno0+1)) );  // 1.2, 1.2.1, etc.
				$subMsg = $this->getpart($mbox,$msgNo,$p2,($i+1).'.'.($partno0+1));  // 1.2, 1.2.1, etc.
				$message['plain'] .= $subMsg['plain'];
				$message['html'] .= $subMsg['html'];
		//		$message['attachments'] = array_merge($message['attachments'],$subMsg['attachments']);
			}
		}	

		return $message;
	}

	function getdecodevalue($message,$coding) {
		switch($coding) {
			case 0:
			case 1:
				$message = imap_8bit($message);
				break;
			case 2:
				$message = imap_binary($message);
				break;
			case 3:
			case 5:
				$message=imap_base64($message);
				break;
			case 4:
				$message = imap_qprint($message);
				break;
		}
		return $message;
	}


	function getdata($mbox, $msgNo) {
	

		$structure = imap_fetchstructure($mbox, $msgNo);    
		$parts = $structure->parts;
		$fpos=2;
		
		$message = array('plain'=>'','html'=>'','attachments'=>array(), 'subparts'=>array());
		//$message = array('plain'=>'','html'=>'','attachments'=>array(), 'subparts'=>array(), 'partTypes'=>array(), 'structure'=>$structure);
		$enum = array();
		$enum["attachment"]["type"][0] = "text";
		$enum["attachment"]["type"][1] = "multipart";
		$enum["attachment"]["type"][2] = "message";
		$enum["attachment"]["type"][3] = "application";
		$enum["attachment"]["type"][4] = "audio";
		$enum["attachment"]["type"][5] = "image";
		$enum["attachment"]["type"][6] = "video";
		$enum["attachment"]["type"][7] = "other";
		
		
		
//			for($i = 1; $i <= count($parts); $i++) {
		if (!empty($parts)) {
			for ($i = 0, $j = count($parts); $i < $j; $i++) {
			//foreach ($parts as $i=>$part){
		
				
//				$data = ($i) ? imap_fetchbody($mbox,$jk,$i):  // multipart
//					imap_body($mbox,$jk);  // not multipart
		
				$part = $parts[$i];
	
				if($part->subtype == 'PLAIN') {
					$data = imap_fetchbody($mbox, $msgNo, $i+1);
				}
				else{
					$data = imap_fetchbody($mbox, $msgNo, "1");					
					//$data = imap_fetchbody($mbox, $msgNo, $i+1 . ".1.2");
				}
		

			// Any part may be encoded, even plain text messages, so check everything.
				if ($part->encoding==4)
				{
					$data = quoted_printable_decode($data);
				}
				else if ($part->encoding==3)
				{
					$data = base64_decode($data);
				}
	
	/*			$message['partTypes'][$i] = array('type'=>$part->type,'hasData'=>empty($data),'subType'=>$part->subtype
												, 'encoding'=>$part->encoding, 'disposition'=>$part->disposition
												, 'params'=>$part->parameters, 'rawData'=>$data);
	*/
				if ($part->type==0) {
					// Messages may be split in different parts because of inline attachments,
					// so append parts together with blank row.
					if (strtolower($part->subtype)=='plain')
					{
						$message['plain'] .= trim($data) ."\n\n";
					}
					else
					{
						//possibly convert charset
						if($part->ifparameters)
						{
							foreach($part->parameters as $param)
							{
								if(strtoupper($param->attribute)=="CHARSET")
								{
									$data = iconv($param->value, "UTF-8",$data);
									break;
								}
							}
						}
						$message['html'] .= $data ."<br><br>";
					}
;
	//				$charset = $params['charset'];  // assume all parts are same charset
				}
			
				// MULTIPART/ALTERNATIVE : TEXT and HTML
				else if ($part->type==1 && $data) {
					//nothing??	
				}
				// EMBEDDED MESSAGE
				// Many bounce notifications embed the original message as type 2,
				// but AOL uses type 1 (multipart), which is not handled here.
				// There are no PHP functions to parse embedded messages,
				// so this just appends the raw source to the main message.
				else if ($part->type==2 && $data) {
					$message['plain'] .= trim($data) ."\n\n";
				}
	
				// ATTACHMENTS
				if($part->disposition == "ATTACHMENT" || $part->disposition == 'inline') {
					$attachment = array();
					$attachment['type'] = $enum["attachment"]["type"][$part->type] . "/" . strtolower($part->subtype);
					$attachment["subtype"] = strtolower($part->subtype);
					$attachment['ext']=$part->subtype;
					$attachment['byteCount']=$part->bytes;
	
					$pn=0;
					while($part->dparameters[$pn])
					{
						if($part->dparameters[$pn]->attribute=='FILENAME')
						{
							$attachment['filename']=$part->dparameters[$pn]->value;
							break;
						}
						$pn++;
					}
					
					
				//	$mege = imap_fetchbody($mbox,$msgNo,$fpos);  //we don't dl the data until the user actually asks for it
					
					$attachment['fpos'] = $fpos;
					$attachment['data'] = '';//$mege;
						
					//$data=$this->getdecodevalue($mege,$part->type);	
					
					array_push($message['attachments'],$attachment);
					
					$fpos+=1;
				}
				
				if ($part->parts) {
					foreach ($part->parts as $partno0=>$p2){
						//array_push($message['subparts'], $this->getpart($mbox,$msgNo,$p2,($i+1).'.'.($partno0+1)) );  // 1.2, 1.2.1, etc.
						$subMsg = $this->getpart($mbox,$msgNo,$p2,($i+1).'.'.($partno0+1));  // 1.2, 1.2.1, etc.
						$message['plain'] .= $subMsg['plain'];
						$message['html'] .= $subMsg['html'];
				//		$message['attachments'] = array_merge($message['attachments'],$subMsg['attachments']);
					}
				}				
				
			}			
		}
		else
		{
			$message['plain'] = imap_body($mbox, $msgNo);
		}

		return $message;
	}
	
	function moveMessage($messageID, $targetMailboxName)
	{
		//connect to the lastMailboxName box; connection creds and box were supplied in the constructor
		$connectError = $this->connect();
		if(!$this->imapStream){
			return;
		}
		//get the state of the mailbox, including the number of messages in it
		$boxSummary = imap_check($this->imapStream); 
		//get the headers for all messages, so we can compare them
		$msgOverviews = imap_fetch_overview($this->imapStream, "1:{$boxSummary->Nmsgs}",0);
				
		foreach($msgOverviews as $msgOvv){
			if(	$msgOvv->message_id == $messageID ){
				imap_mail_move($this->imapStream, $msgOvv->msgno, $targetMailboxName);
			}
		}
		$this->close();		
	}
	
	function getDelMsgIds($dbMsgIds)
	{
		$connectError = $this->connect();
		if(!$this->imapStream){
			return;
		}
		
		$boxSummary = imap_check($this->imapStream); 

		$msgOverviews = imap_fetch_overview($this->imapStream, "1:{$boxSummary->Nmsgs}",0);
		
		$msgIds = array();		
		foreach($msgOverviews as $msgOvv){			
			try{
				array_push($msgIds, $msgOvv->message_id);
			}
			catch(Exception $e){
				error_log($e);
			}			
		}
		
		$delMsgIds = array();
		foreach($dbMsgIds as $dbMsgId)
		{
			if(!in_array($dbMsgId, $msgIds))
			{				
				try{
					array_push($delMsgIds, $dbMsgId);
				}
				catch(Exception $e){
					error_log($e);
				}				
			}
		}
		
		$this->close();
		
		return $delMsgIds;			
	}
}
?>