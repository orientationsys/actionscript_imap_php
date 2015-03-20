package com.robotblimp.helium.services.msg
{
	import com.hurlant.crypto.prng.ARC4;
	
	public class IMFMessage
	{
		public var mailMessageGUID:String;
		public var taskGUID:String;
		public var userGUID:String;
		
		public var messageID:String;
		public var profileGUID:String;
		public var lastMailboxName:String;
		public var subject:String;
		
		public var fromAddress:String;
		public var toAddress:String;
		public var replyToAddress:String;
		public var ccAddress:String;
		public var bccAddress:String;
		
		public var senderAddress:String;
		
		//                in-reply-to /
		//                references /
		
		//                comments /
		//                keywords /
		//                optional-field
		public var messageDate:String;
		
		public var mimeVersion:String;
		public var contentType:String;
		public var rawBodyStructure:String;
		public var bodyStructure:String;
		
		public var messageIMAPNum:int;
		
		public var bodyText:String;
		public var bodyTextFetch:String;
		
		public var bodyHTML:String;
		public var bodyHTMLFetch:String;
		
		public var attachments:Array = new Array();
		public var attachmentCount:int;
		
		
		public var dateCreated:Number;
		public var dateModified:Number;
		
		public function IMFMessage()
		{				
		}
		
		
		
	}
}