<?php


// Class ExchangeWebDAV

class ExchangeWebDAV{
	
	private $_password;
	private $_username;
	private $domain;
	private $mailbox;
	private $server;
	private $protocol;
	private $usesFBA;
	private $exchangeVersion;
	private $cookiefile;
	private $folderName;
	private $authDestination;
	
	private $cookies = array();
	private $headers = array();
	
	private $path; 
	private $mode; 
	private $options; 
	private $opened_path; 
	private $buffer; 
	private $pos; 
	
	private $debug=false;
	
	public function __construct($pUsername, $pPassword, $pDomain, $pMailbox, $pAuthDestination, $pServer, $pProtocol, $pExchangeVersion, $pFolder){
		$this->_username 		= $pUsername;
		$this->_password 		= $pPassword;
		$this->domain			= $pDomain;
		if($this->domain){
			$this->_username = $this->domain."\\".$this->_username;
		}		
		
		$this->mailbox			= $pMailbox;
		$this->authDestination	= $pAuthDestination;
		$this->server 			= $pServer;
		$this->protocol 		= $pProtocol;
		$this->usesFBA 			= true;
		$this->exchangeVersion 	= $pExchangeVersion;
		$this->folderName 		= str_replace(" ","%20",$pFolder);
	}
	
	public function setDebug($b){
		$this->debug = $b;	
	}
	
	public function setUsername($username){
		$this->_username = $username;	
	}
	
	public function setPassword($pass){
		$this->_password = $pass;	
	}
	
	public function setServer($srv){
		$this->server = $srv;	
	}
	
	public function setProtocol($p){
		$this->protocol = $p;	
	}
	
	public function useFBA($b){
		$this->usesFBA = $b;
	}
	
	public function setExchangeVersion($v){
		$this->exchangeVersion = $v;	
	}
		
	public function setFolderName($f){
		$this->folderName = str_replace(" ","%20",$f);	
	}
	
	
	public function testCredentials(){
		$this->open();
		return $this->getCredTestValidity();
	}
	
	
	public function getBoxMessagesExcept($messageIDs){
		$this->open();	
		return $this->getFolderMessagesExcept($messageIDs);
	}
	
	public function getAttachment($folderAndFile){
		$this->open();
		return $this->getAttachmentByFolderAndFile($folderAndFile);		
	}
	
	public function listFoldersUnderFolder(){
		$this->open();
		$this->getFolderEnum();
		echo $this->buffer;
	}
	
	public function moveMessage($subjects, $messageURI, $toURI){
		$this->move($subjects, $messageURI, $toURI);
	
		return $this->headers;
	}
	
	
	private function myProtocolAndServer(){
		return $this->protocol.'://'.$this->server;	
	}
	
	public function open(){
		if($this->usesFBA){
			$this->authenticateFBA();	
		}	
	}
	
	private function getFolderEnum(){
		$xmlrequest = '<?xml version="1.0"?>';
		$xmlrequest .= "<a:searchrequest xmlns:a=\"DAV:\" xmlns:s=\"http://schemas.microsoft.com/exchange/security/\">";
		$xmlrequest .= '<a:sql>';
		$xmlrequest .= "SELECT 
		       \"DAV:displayname\", \"DAV:href\", \"http://schemas.microsoft.com/exchange/permanenturl\"
       			FROM SCOPE('deep traversal of \"{$this->protocol}://{$this->server}/exchange/{$this->mailbox}/{$this->folderName}\"')
   				</a:sql>
			</a:searchrequest>";
		$path = "{$this->protocol}://{$this->server}/exchange/{$this->mailbox}/{$this->folderName}";
	
		$this->Debug("getFolderEnum xml:$xmlrequest");
		$this->executeDAV($path, 'SEARCH', $xmlrequest);

	}
	
	private function getCredTestValidity(){
	
//		$path = "{$this->protocol}://{$this->server}/exchange/{$this->mailbox}/{$this->folderName}";
		$path = "{$this->protocol}://{$this->server}/exchange/{$this->mailbox}";
		
		$xmlrequest = '<?xml version="1.0"?>';
		$xmlrequest .= "<a:searchrequest xmlns:a=\"DAV:\" xmlns:s=\"http://schemas.microsoft.com/exchange/security/\">";
		$xmlrequest .= '<a:sql>';
		$xmlrequest .= 'SELECT 
					"DAV:resourcetype" 
					';
		$xmlrequest .= " FROM \"$path\" ";
	
//		$xmlrequest .= " WHERE \"urn:schemas:mailheader:from\" !='' ";	
	
		$xmlrequest .= '</a:sql></a:searchrequest>';
		
		$this->Debug("path: $path\nxml:$xmlrequest");

		$this->executeDAV($path, 'SEARCH', $xmlrequest);

		//translate xml to JSON
		$xml = new DOMDocument();

		@$xml->loadXML($this->buffer);
		$msgs = $xml->getElementsByTagName('response');
		
		$i=0;
		foreach($msgs as $msg){
			$i++;
			if(0<$i)
			{
				break;
			}
		}

		return $i;
	}
	
	private function getFolderMessagesExcept($messageIDs){
	
		$path = "{$this->protocol}://{$this->server}/exchange/{$this->mailbox}/{$this->folderName}";
		//$path = "https://webmail.ihostexchange.net/exchange/rbi@chuckaduck.com/@Now";
		$xmlrequest = '<?xml version="1.0"?>';
		$xmlrequest .= "<a:searchrequest xmlns:a=\"DAV:\" xmlns:s=\"http://schemas.microsoft.com/exchange/security/\">";
		$xmlrequest .= '<a:sql>';
		$xmlrequest .= 'SELECT 
					"DAV:displayname" 
					,"urn:schemas:httpmail:subject" 
					,"urn:schemas:mailheader:from"
					,"urn:schemas:httpmail:fromname"
					,"urn:schemas:httpmail:fromemail"
					,"urn:schemas:mailheader:to"
					,"urn:schemas:mailheader:date"
					,"urn:schemas:mailheader:message-id"
					,"urn:schemas:httpmail:textdescription"
					,"urn:schemas:httpmail:hasattachment"
					';
		$xmlrequest .= " FROM \"$path\" ";
	
		$xmlrequest .= " WHERE \"urn:schemas:mailheader:from\" !='' ";	
		if(0<count($messageIDs)){
			$rejectIDs = array_map(array($this,formatMessageID),$messageIDs);

			$xmlrequest .= ' AND ' . join($rejectIDs, " AND ");
		}

		$xmlrequest .= '</a:sql></a:searchrequest>';

		$this->Debug("path: $path\nxml:$xmlrequest");

		$this->executeDAV($path, 'SEARCH', $xmlrequest);

		$res = array();
		//translate xml to JSON
//		if($this->buffer){
			$xml = new DOMDocument();
			@$xml->loadXML($this->buffer);
		
//		$msgs = $xml->getElementsByTagName('propstat');
			$msgs = $xml->getElementsByTagName('response');
		
			foreach($msgs as $msg){
				array_push($res, $this->BundleMessage( $msg ));
			}
//		}
		return $res;
	}
	
	private function formatMessageID($id){
		$id = str_replace("<", "&lt;", $id);
		$id = str_replace(">", "&gt;", $id);
		
		return "\"urn:schemas:mailheader:message-id\" != '$id'" ;
	}
	
	private function BundleMessage( $msg ){
		//makes a standard hash object from an xml one	
		//subject, from, to, date, message_id, html, plain
		
		$res = array('message_id'=> base64_encode($msg->getElementsByTagName('message-id')->item(0)->nodeValue)
					,'subject'=> base64_encode($msg->getElementsByTagName('subject')->item(0)->nodeValue)
					,'fromemail'=> base64_encode($msg->getElementsByTagName('fromemail')->item(0)->nodeValue)
					,'fromname'=> base64_encode($msg->getElementsByTagName('fromname')->item(0)->nodeValue)
					,'to'=> base64_encode($msg->getElementsByTagName('to')->item(0)->nodeValue)					
					,'date'=> base64_encode($msg->getElementsByTagName('date')->item(0)->nodeValue)
					,'plain'=> base64_encode($msg->getElementsByTagName('textdescription')->item(0)->nodeValue)
					,'attachments'=>array()
					);
		
		if(1==$msg->getElementsByTagName('hasattachment')->item(0)->nodeValue){
			$href = $msg->getElementsByTagName('href')->item(0)->nodeValue;
			$pos = strrpos($href, "/");
			$eml = substr($href, $pos);

			$res['attachments'] = $this->enumAttachments($eml);
		}
		
		return $res;	
	}
	
	private function authenticateFBA(){

		//set up authorization parameters and values
		
		$authParams = array('destination'		=> $this->protocol."://".$this->authDestination
							, 'username'		=> $this->_username
							,'password'			=> $this->_password
							,'flags'			=> "0"
							,'SubmitCreds'		=> "Log On"
							,'trusted' 			=> "0"
							);
	
		//$authParams['destination'] = $this->myProtocolAndServer().'/exchange/'.$this->mailbox;			
				
		$tmpAuthArray =array();
		foreach ($authParams as $key=>$value) {
			array_push($tmpAuthArray, urlencode($key)."=".urlencode($value) );
		}
        $authString = join("&", $tmpAuthArray);
		
		
//echo "authstring: $authString\n\n";
		
		if($this->exchangeVersion == 2007){
			$authPath = '/exchweb/bin/auth/owaauth.dll';			
		}
		else if($this->exchangeVersion == 2003){
			$authPath = '/owa/auth/owaauth.dll';
		}
		else{
			$this->exchangeVersion = 2007;
			$authPath = '/exchweb/bin/auth/owaauth.dll';
		}

	
		$headers = array(
						 'Content-Type: application/x-www-form-urlencoded'
					//	 ,'Connection: keep-alive'
						 ,"Content-Length: ".strlen($authString)
					//	 ,'User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1.7) Gecko/20091221 Firefox/3.5.7'
					//	 ,'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
					//	 ,'Accept-Language: en-us,en;q=0.5'
					//	 ,'Accept-Encoding: gzip,deflate'
					//	 ,'Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7'
					//	 ,'Keep-Alive: 300'
					//	 ,'Connection: keep-alive'

					//	 ,'Expect:'
					
						 );

		$this->cookiefile = tempnam ("/tmp", "CURLCOOKIE"); 
	
	
			//initialize to e.g. https://webmail.ihostexchange.net/exchweb/bin/auth/owaauth.dll
		$this->ch = curl_init($this->protocol.'://'.$this->server.$authPath); 

		curl_setopt($this->ch, CURLOPT_POST, true);
		curl_setopt($this->ch, CURLOPT_RETURNTRANSFER, true); 
		curl_setopt($this->ch, CURLOPT_SSL_VERIFYPEER, false);
		curl_setopt($this->ch, CURLOPT_FOLLOWLOCATION, false); //refuse redirect
		curl_setopt($this->ch, CURLOPT_POSTFIELDS, $authString);
		curl_setopt($this->ch, CURLOPT_HEADERFUNCTION, array(&$this,'readHeader'));
		curl_setopt($this->ch, CURLOPT_COOKIEJAR, $this->cookiefile); 

		curl_setopt($this->ch, CURLOPT_HTTPHEADER, $headers); 		
	
		curl_setopt($this->ch, CURLOPT_TIMEOUT, 4); // times out after 5s
//		echo "executing:\n";

		$this->buffer = curl_exec($this->ch); 
		$this->Debug("Authorization? Have cookies:" . json_encode($this->cookies) .$this->buffer);
		
		if(curl_errno($this->ch))
		{
			$this->Debug('Curl error: ' . curl_error($this->ch));
		}
		curl_close($this->ch);	
		
	}
	
		
	private function readHeader($ch, $header) {
		$cookieNames = array('OwaLbe','sessionid','cadata','UserContext');
		$this->Debug('Header: '.$header);
		foreach($cookieNames as $cName){
			$val = $this->extractCustomHeader($cName.'=', ';', $header);
			if($val){
				array_push($this->cookies, $cName.'='.$val);
			}
		}
		array_push($this->headers, $header);
//		echo "full header: $header\n";
		return strlen($header);
	}
	
	private function extractCustomHeader($start,$end,$header) {
		$pattern = '/'. $start .'(.*?)'. $end .'/';
		if (preg_match($pattern, $header, $result)) {
			return $result[1];
		} else {
			return false;
		}
	}
	

	/* Create the buffer by requesting the url through cURL */ 
	private function executeDAV($path, $verb, $xmlrequest) { 
	
		$this->ch = curl_init($path); 
		
		$headers = array( 'Connection: Keep-Alive'
						 ,'Content-Type: text/xml; charset=UTF-8'
						 ,'Depth: infinity'
						 ,'Translate: f'
						 , 'Accept: */*'
						 );


		curl_setopt($this->ch, CURLOPT_RETURNTRANSFER, true); 
		curl_setopt($this->ch, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_1_1); 
		curl_setopt($this->ch, CURLOPT_SSL_VERIFYPEER, false);		
		curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, strtoupper($verb) ); 
		curl_setopt($this->ch, CURLOPT_POSTFIELDS, $xmlrequest); 
		
//		curl_setopt($this->ch, CURLOPT_COOKIEJAR, 'cookiefile.txt');
//		curl_setopt($this->ch, CURLOPT_COOKIEFILE, 'cookiefile.txt');
		curl_setopt($this->ch, CURLOPT_HEADERFUNCTION, array(&$this,'readHeader'));	
 		curl_setopt($this->ch, CURLOPT_COOKIEJAR, $this->cookiefile); 
		
		$cookieString = implode("; ", $this->cookies);
//		echo $cookieString;
		curl_setopt($this->ch, CURLOPT_COOKIE, $cookieString);	
		
	
	
		curl_setopt($this->ch, CURLOPT_HTTPHEADER, $headers); 
		curl_setopt($this->ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC|CURLAUTH_NTLM); 
		curl_setopt($this->ch, CURLOPT_USERPWD, $this->_username.':'.$this->_password); 
	
		$this->buffer = curl_exec($this->ch); 
		$this->Debug("executedDAV with xml:$xmlrequest\n".$this->buffer);
		
		if(curl_errno($this->ch))
		{
			$this->Debug('Curl error: ' . curl_error($this->ch));
		}
		curl_close($this->ch);

	}
	
	private function enumAttachments($msgRefEML){
	/*
		X-MS-ENUMATTS /exchange/useralias/inbox/OutlookMsg.eml HTTP/1.1
		Host: www.example.com  	
		// http://msdn.microsoft.com/en-us/library/aa126042%28EXCHG.65%29.aspx
	*/


		$path = "{$this->protocol}://{$this->server}/exchange/{$this->mailbox}/{$this->folderName}/$msgRefEML";

		$this->ch = curl_init($path); 

		$headers = array( 'Connection: Keep-Alive'
						 ,'Depth: 0'
						 ,'Translate: f'
						 , 'Accept: */*'
						 );


		curl_setopt($this->ch, CURLOPT_RETURNTRANSFER, true); 
		curl_setopt($this->ch, CURLOPT_SSL_VERIFYPEER, false);			
		curl_setopt($this->ch, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_1_1); 
		curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, "X-MS-ENUMATTS" ); 
		curl_setopt($this->ch, CURLOPT_POSTFIELDS, "/exchange/{$this->mailbox}/{$this->folderName}/$msgRefEML"); 
 		curl_setopt($this->ch, CURLOPT_COOKIEJAR, $this->cookiefile); 		
		
		curl_setopt($this->ch, CURLOPT_HEADERFUNCTION, array(&$this,'readHeader'));	

		$cookieString = implode("; ", $this->cookies);
//		echo $cookieString;
		curl_setopt($this->ch, CURLOPT_COOKIE, $cookieString);	
		
	
	
		curl_setopt($this->ch, CURLOPT_HTTPHEADER, $headers); 
//		curl_setopt($this->ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC|CURLAUTH_NTLM); 
//		curl_setopt($this->ch, CURLOPT_USERPWD, $this->_username.':'.$this->_password); 
	
		$xmlstream = curl_exec($this->ch); 
//		$this->Debug("Enum Attachments\n".$this->buffer);
		$this->Debug("Enum Attachments\n".$xmlstream);
		curl_close($this->ch);
		
//echo $xmlstream;
		//get attachment path from xml
		$xml = new DOMDocument();
		$xml->loadXML($xmlstream);
		$attaches = $xml->getElementsByTagName('response');
		$attachments = array();
		foreach($attaches as $attach){
			$href = $attach->getElementsByTagName('href')->item(0)->nodeValue;
			$href = str_replace($this->protocol.'://'.$this->server.'/exchange/'.$this->mailbox.'/','',$href);
			$filename = $attach->getElementsByTagName('attachmentfilename')->item(0)->nodeValue;
			$size = $attach->getElementsByTagName('x0e200003')->item(0)->nodeValue;
			$ext = $attach->getElementsByTagName('x3703001f')->item(0)->nodeValue;
			array_push($attachments, array('href'=> base64_encode($href), 'filename'=> base64_encode($filename), 'size'=>$size, 'ext'=> base64_encode($ext)) );
		}

		return $attachments;
	}
	
	private function getAttachmentByFolderAndFile($folderAndFile){
	
		$path = "{$this->protocol}://{$this->server}/exchange/{$this->mailbox}/" . $folderAndFile;
		$path = str_replace(' ','%20',$path);
//		$path = "{$this->protocol}://{$this->server}/exchange/{$this->_username}/{$this->folderName}/four%20attachments.EML/06eagle.jpg";

//echo $path;

$this->Debug("getting attachment at path: " . $path);
		
		$this->ch = curl_init($path); 

		$headers = array('Translate: f');


		curl_setopt($this->ch, CURLOPT_RETURNTRANSFER, true); 
		curl_setopt($this->ch, CURLOPT_SSL_VERIFYPEER, false);				
//		curl_setopt($this->ch, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_1_1); 
		curl_setopt($this->ch, CURLOPT_HTTPGET, true ); 
//		curl_setopt($ch, CURLOPT_POSTFIELDS, "/exchange/{$this->_username}/$folderAndFile"); 
		
		curl_setopt($this->ch, CURLOPT_HEADERFUNCTION, array(&$this,'readHeader'));	

		curl_setopt($this->ch, CURLOPT_COOKIEJAR, $this->cookiefile); 
		$cookieString = implode("; ", $this->cookies);
		curl_setopt($this->ch, CURLOPT_COOKIE, $cookieString);	
	
		curl_setopt($this->ch, CURLOPT_HTTPHEADER, $headers); 
		curl_setopt($this->ch, CURLOPT_HTTPAUTH, CURLAUTH_NTLM); 
		curl_setopt($this->ch, CURLOPT_USERPWD, $this->_username.':'.$this->_password);
	
		$this->buffer = curl_exec($this->ch);
		$this->Debug("Got attachments");		
		$base64EncodedFile = base64_encode( $this->buffer ); 
		
		curl_close($this->ch);
		
		return $base64EncodedFile;

	}
	
	private function Debug($s){
		if($this->debug){
			echo "\n\n$s\n\n";
		}
	}
	
	private function move($subjects, $resourceURI, $targetURI) { 
	
		foreach($subjects as $subject)
		{
			$path = "{$this->protocol}://{$this->server}/exchange/{$this->mailbox}/{$resourceURI}/{$subject}.EML";
			//$path = "https://webmail.ihostexchange.net/exchange/rbi@chuckaduck.com/@Now/test.EML";	
			$this->ch = curl_init($path); 
	
			$headers = array( 'Connection: Keep-Alive'
							 ,'Depth: infinity'
							 ,'Translate: f'
							 , 'Accept: */*'
							 ,'Destination: ' . "{$this->protocol}://{$this->server}/exchange/{$this->mailbox}/{$targetURI}/{$subject}.EML"
							 //,'Destination: ' . "https://webmail.ihostexchange.net/exchange/rbi@chuckaduck.com/@Someday/test.EML"
							 );
	
	
			curl_setopt($this->ch, CURLOPT_RETURNTRANSFER, true); 
			curl_setopt($this->ch, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_1_1); 
			curl_setopt($this->ch, CURLOPT_SSL_VERIFYPEER, false);		
			curl_setopt($this->ch, CURLOPT_CUSTOMREQUEST, "MOVE" ); 
			curl_setopt($this->ch, CURLOPT_HEADERFUNCTION, array(&$this,'readHeader'));	
			curl_setopt($this->ch, CURLOPT_HTTPHEADER, $headers); 
	
			curl_setopt($this->ch, CURLOPT_COOKIEJAR, $this->cookiefile); 
			$cookieString = implode("; ", $this->cookies);
			curl_setopt($this->ch, CURLOPT_COOKIE, $cookieString);		
			curl_setopt($this->ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC|CURLAUTH_NTLM); 
			curl_setopt($this->ch, CURLOPT_USERPWD, $this->_username.':'.$this->_password); 
		
			$this->buffer = curl_exec($this->ch); 
			$this->Debug("move $subject to $targetURI\n".$this->buffer);
			
			if(curl_errno($this->ch))
			{
				$this->Debug('Curl error: ' . curl_error($this->ch));
			}
			curl_close($this->ch);
		}
	}
	
} 


	
	
	
	
	




?>