<?php
include_once 'class_HeliumDatabase.php';

class HeliumAuthenticator{
	
	private $userGUID;
	
	public function __construct($userGUID=0){
		$this->userGUID = $userGUID;		
	}
	
	public function authenticate($pass){
		$DB = new HeliumDatabase();

		if(!$DB){
			return FALSE;
		}
		$pash = hash('sha256',$pass);

		$dbps = $DB->prepare("SELECT properName FROM centraluser WHERE userGUID=? AND pash=?");
		$dbps->bind_param('ss', $this->userGUID, $pash);
		$dbps->execute();
		$dbps->bind_result($properName);
		$dbps->fetch();
		$dbps->close();
		if($properName){
			return TRUE;
		}
		
		return FALSE;		
	}
	

	public function webAuthenticate($email, $pass){
		$DB = new HeliumDatabase();

		if(!$DB){
			return FALSE;
		}

		$pash = hash('sha256', $pass);
	
		$dbps = $DB->prepare("SELECT userGUID, properName FROM centraluser WHERE primaryEmailAddress=? AND pash=?");
		$dbps->bind_param('ss', $email, $pash);
		$dbps->execute();
		$dbps->bind_result($userGUID, $properName);
		$dbps->fetch();
		$dbps->close();
		if($userGUID){
			return array('userGUID'=>$userGUID, 'properName'=>$properName, 'auth'=>1);
		}
		
		return array('userGUID'=>'', 'properName'=>'', 'auth'=>0);
	}
	
	public function emailExists($email){
		$DB = new HeliumDatabase();

		if(!$DB){
			return FALSE;
		}
		
		$dbps = $DB->prepare("SELECT userGUID, properName FROM centraluser WHERE primaryEmailAddress=?");
		$dbps->bind_param('s', $email);
		$dbps->execute();
		$dbps->bind_result($userGUID, $properName);
		$dbps->fetch();
		$dbps->close();
		if($properName){
			return TRUE;
		}
		
		return FALSE;
		
	}
		
	/**
		Validate an email address.
		Provide email address (raw input)
		Returns true if the email address has the email 
		address format and the domain exists.
		http://www.linuxjournal.com/article/9585?page=0,3
	*/
	public function validEmail($email)
	{
	   $isValid = true;
	   $atIndex = strrpos($email, "@");
	   if (is_bool($atIndex) && !$atIndex)
	   {
		  $isValid = false;
	   }
	   else
	   {
		  $domain = substr($email, $atIndex+1);
		  $local = substr($email, 0, $atIndex);
		  $localLen = strlen($local);
		  $domainLen = strlen($domain);
		  if ($localLen < 1 || $localLen > 64)
		  {
			 // local part length exceeded
			 $isValid = false;
		  }
		  else if ($domainLen < 1 || $domainLen > 255)
		  {
			 // domain part length exceeded
			 $isValid = false;
		  }
		  else if ($local[0] == '.' || $local[$localLen-1] == '.')
		  {
			 // local part starts or ends with '.'
			 $isValid = false;
		  }
		  else if (preg_match('/\\.\\./', $local))
		  {
			 // local part has two consecutive dots
			 $isValid = false;
		  }
		  else if (!preg_match('/^[A-Za-z0-9\\-\\.]+$/', $domain))
		  {
			 // character not valid in domain part
			 $isValid = false;
		  }
		  else if (preg_match('/\\.\\./', $domain))
		  {
			 // domain part has two consecutive dots
			 $isValid = false;
		  }
		  else if (!preg_match('/^(\\\\.|[A-Za-z0-9!#%&`_=\\/$\'*+?^{}|~.-])+$/', str_replace("\\\\","",$local)))
		  {
			 // character not valid in local part unless 
			 // local part is quoted
			 if (!preg_match('/^"(\\\\"|[^"])+"$/', str_replace("\\\\","",$local)))
			 {
				$isValid = false;
			 }
		  }
		  if ($isValid && !(checkdnsrr($domain,"MX") || checkdnsrr($domain,"A")))
		  {
			 // domain not found in DNS
			 $isValid = false;
		  }
	   }
	   return $isValid;
	}
	
}


?>