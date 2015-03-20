package com.robotblimp.helium.core
{
	import com.robotblimp.helium.constants.*;
	import com.robotblimp.helium.dataModel.*;
	import com.robotblimp.helium.dataModel.profileClasses.ExchangeProfileVO;
	import com.robotblimp.helium.dataModel.profileClasses.IMAPProfileVO;
	import com.robotblimp.helium.services.db.*;
	import com.robotblimp.helium.services.msg.IMFMessage;
	
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	
	import mx.core.FlexGlobals;
	
	public class MessageManager
	{
		private var DB:Database;
				
		private var sql:SQLStatement;
		
		private var _userGUID:String;
		
		public function MessageManager(userGUID:String)
		{
			DB = FlexGlobals.topLevelApplication.Sys.DB;					
			_userGUID = userGUID;
		}
		
		//get messageIDs
		public function getMessageIDs():Array
		{
			
			return [];
		}
		public function getProfileMessageIDs(profileGUID:String):Array
		{	
			sql = new SQLStatement();
			sql.text = "SELECT mailMessageGUID, messageID, lastMailboxName FROM mailmessage " +
				"WHERE userGUID=:UserGUID AND profileGUID=:ProfileGUID ";
			sql.parameters[":UserGUID"] = _userGUID;
			sql.parameters[":ProfileGUID"] = profileGUID;
			DB.doSQL(sql);
			
			var messageIDs:Array = sql.getResult().data;
			if(messageIDs) return messageIDs;
			
			return new Array();			
		}
		
		public function getMessageIDsForTasks(mailbox:String):Array
		{
			sql = new SQLStatement();
			sql.text = "SELECT * FROM mailmessage WHERE lastMailboxName=:mailbox";
			sql.parameters[":mailbox"] = mailbox;
			DB.doSQL( sql );
			
			return sql.getResult().data;
		}
		public function getMessageInfo(msgID:String):Object
		{
			sql = new SQLStatement();
			sql.text = "SELECT mailMessageGUID, taskGUID, lastMailboxName FROM mailmessage WHERE messageID=:messageID";
			sql.parameters[":messageID"] = msgID;			
			DB.doSQL( sql );
			
			var res:Array = sql.getResult().data;
			if(res)
			{
				return res[0];
			}
			else
			{
				return null;
			}
		}
		
		public function getMailMessageInfo(mailMessageGUID:String):Object
		{
			sql = new SQLStatement();
			sql.text = "SELECT * FROM mailmessage WHERE mailMessageGUID=:MailMessageGUID";
			sql.parameters[":MailMessageGUID"] = mailMessageGUID;			
			DB.doSQL( sql );
			 
			var res:Array = sql.getResult().data;
			if(res)	return res[0];
			
			return null;
			
		}
/*		public function getTaskMessageInfo(taskGUID:String):Object
		{
			sql = new SQLStatement();
			sql.text = "SELECT mailMessageGUID, messageID, profileGUID, lastMailboxName, lastOrganizeBox " + 
					"FROM mailmessage " + 
					"WHERE taskGUID=:TaskGUID";
			sql.parameters[":TaskGUID"] = taskGUID;			
			DB.doSQL( sql );
			
			var res:Array = sql.getResult().data;
			if(res)
			{
				return res[0];
			}
			else
			{
				return null;
			}
		}*/

		public function getTaskMessageInfo(taskGUID:String):Object
		{
			sql = new SQLStatement();
			sql.text = "SELECT mailMessageGUID, messageID, profileGUID, lastMailboxName " + 
				"FROM mailmessage " + 
				"WHERE taskGUID=:TaskGUID";
			sql.parameters[":TaskGUID"] = taskGUID;			
			DB.doSQL( sql );
			
			var res:Array = sql.getResult().data;
			if(res)
			{
				return res[0];
			}
			else
			{
				return null;
			}
		}
		
/*		public function storeTaskMessage(taskGUID:String, noteGUID:String, profileGUID:String, mailboxName:String, organizeBox:uint, msg:IMFMessage):String
		{
			sql = new SQLStatement();
			var newMailMessageGUID:String = System.newGUID();
			sql.text = "INSERT INTO mailmessage ( " + 
					"mailMessageGUID, taskGUID, noteGUID, userGUID " + 
					", messageID, profileGUID " + 
					", lastMailboxName, lastOrganizeBox, subject, fromAddress " + 
					", toAddress, replyToAddress, ccAddress " + 
					", bccAddress, messageDate, mimeVersion " + 
					", contentType, bodyStructure, dateCreated, dateModified " +
					") " + 
					"VALUES ( " + 
					":MailMessageGUID, :TaskGUID, :NoteGUID, :UserGUID, :MessageID, :ProfileGUID " + 
					", :LastMailboxName, :LastOrganizeBox, :Subject, :FromAddress " + 
					", :ToAddress, :ReplyToAddress, :CcAddress " + 
					", :BccAddress, :MessageDate, :MimeVersion, :ContentType, :BodyStructure " + 
					", strftime('%s','now'), strftime('%s','now') " + 
					")";
			sql.parameters[":MailMessageGUID"] = newMailMessageGUID;
			sql.parameters[":TaskGUID"] = taskGUID;
			sql.parameters[":NoteGUID"] = noteGUID;
			sql.parameters[":UserGUID"] = _userGUID;
			sql.parameters[":MessageID"] = msg.messageID;
			sql.parameters[":ProfileGUID"] = profileGUID;
			sql.parameters[":LastMailboxName"] = mailboxName;
			sql.parameters[":LastOrganizeBox"] = organizeBox;
			sql.parameters[":Subject"] = msg.subject;
			sql.parameters[":FromAddress"] = msg.fromAddress;
			sql.parameters[":ToAddress"] = msg.toAddress;
			sql.parameters[":ReplyToAddress"] = msg.replyToAddress;
			sql.parameters[":CcAddress"] = msg.ccAddress;
			sql.parameters[":BccAddress"] = msg.bccAddress;
			sql.parameters[":MessageDate"] = msg.messageDate;
			sql.parameters[":MimeVersion"] = msg.mimeVersion;
			sql.parameters[":ContentType"] = msg.contentType;
			sql.parameters[":BodyStructure"] = msg.rawBodyStructure;
			
			DB.doSQL( sql );
					
			return newMailMessageGUID;
		}*/

		public function storeTaskMessage(taskGUID:String, profileGUID:String, mailboxName:String, msg:IMFMessage):String
		{
			sql = new SQLStatement();
			var newMailMessageGUID:String = System.newGUID();
			sql.text = "INSERT INTO mailmessage ( " + 
				"mailMessageGUID, taskGUID, userGUID " + 
				", messageID, profileGUID " + 
				", lastMailboxName, subject, fromAddress " + 
				", toAddress, replyToAddress, ccAddress " + 
				", bccAddress, messageDate, mimeVersion " + 
				", contentType, bodyStructure, dateCreated, dateModified " +
				") " + 
				"VALUES ( " + 
				":MailMessageGUID, :TaskGUID, :UserGUID, :MessageID, :ProfileGUID " + 
				", :LastMailboxName, :Subject, :FromAddress " + 
				", :ToAddress, :ReplyToAddress, :CcAddress " + 
				", :BccAddress, :MessageDate, :MimeVersion, :ContentType, :BodyStructure " + 
				", strftime('%s','now'), strftime('%s','now') " + 
				")";
			sql.parameters[":MailMessageGUID"] = newMailMessageGUID;
			sql.parameters[":TaskGUID"] = taskGUID;
			sql.parameters[":UserGUID"] = _userGUID;
			sql.parameters[":MessageID"] = msg.messageID;
			sql.parameters[":ProfileGUID"] = profileGUID;
			sql.parameters[":LastMailboxName"] = mailboxName;
			sql.parameters[":Subject"] = msg.subject;
			sql.parameters[":FromAddress"] = msg.fromAddress;
			sql.parameters[":ToAddress"] = msg.toAddress;
			sql.parameters[":ReplyToAddress"] = msg.replyToAddress;
			sql.parameters[":CcAddress"] = msg.ccAddress;
			sql.parameters[":BccAddress"] = msg.bccAddress;
			sql.parameters[":MessageDate"] = msg.messageDate;
			sql.parameters[":MimeVersion"] = msg.mimeVersion;
			sql.parameters[":ContentType"] = msg.contentType;
			sql.parameters[":BodyStructure"] = msg.bodyStructure;
			
			DB.doSQL( sql );
			
			return newMailMessageGUID;
		}
		/**
		 * make sure that a task's emails messages are in a folder corresponding to the task's organize box
		 */
		public function moveEmailMessagesWithTask(task:FullTask, shouldQueue:Boolean=true):void
		{
			var box:uint = task.organizeBox;
			//does the task have any messages? check its attachments and notes as well
			sql = new SQLStatement();
			//task
			sql.text = "SELECT DISTINCT mm.mailMessageGUID, mm.messageID, mm.lastMailboxName, mm.lastOrganizeBox " +
				", mm.profileGUID, ep.profileType " +
				"FROM mailmessage mm, externalprofile ep " +
				"WHERE mm.userGUID=:UserGUID AND ep.profileGUID=mm.profileGUID " +
				"AND (" +
				"mm.taskGUID=:TaskGUID " +
				"OR mm.noteGUID IN ( SELECT noteGUID FROM note WHERE taskGUID=:TaskGUID ) " +
				"OR mm.mailMessageGUID IN ( SELECT mailMessageGUID FROM attachment WHERE taskGUID=:TaskGUID ) " +
				")";
			sql.parameters[":UserGUID"] = _userGUID;
			sql.parameters[":TaskGUID"] = task.taskGUID;
			sql.itemClass = MessageMoveQueueEntry;
			DB.doSQL(sql);
			var res:SQLResult = sql.getResult();
			if(res.data){
				//queue the move 
				
				sql.text = "UPDATE mailmessage " +
					"SET lastMailboxName=:LastMailboxName, lastOrganizeBox=:LastOrganizeBox " +
					"WHERE userGUID=:UserGUID AND mailMessageGUID=:MailMessageGUID"; 
				
				for each(var mmqe:MessageMoveQueueEntry in res.data){					
					if(UserSettings.Profile_Exchange == mmqe.profileType){
						//get exchange profile
						var exp:ExchangeProfileVO = FlexGlobals.topLevelApplication.US.getExchangeProfile(mmqe.profileGUID);
						mmqe.targetMailboxName = exp.getMailboxNameForBox( task.organizeBox );
					}
					else if(UserSettings.Profile_GMail == mmqe.profileType ||
							UserSettings.Profile_MobileMe == mmqe.profileType ||
							UserSettings.Profile_IMAP == mmqe.profileType){
						var imp:IMAPProfileVO = FlexGlobals.topLevelApplication.US.getIMAPProfile(mmqe.profileGUID);
						mmqe.targetMailboxName = imp.getMailboxNameForBox( task.organizeBox );
					}
					mmqe.targetOrganizeBox = task.organizeBox;
					if(shouldQueue) mmqe.saveToQueue(_userGUID,DB);
					
					//update each message to have the current box and new profile-based lastMailbox
					sql.clearParameters();
					sql.parameters[":LastMailboxName"] = mmqe.targetMailboxName;
					sql.parameters[":LastOrganizeBox"] = mmqe.targetOrganizeBox;
					sql.parameters[":MailMessageGUID"] = mmqe.mailMessageGUID;
					sql.parameters[":UserGUID"] = _userGUID;
					DB.doSQL(sql);
				}
				
				if(shouldQueue) FlexGlobals.topLevelApplication.imapChecker.moveQueuedMessages();
				
			}			
		}
		
		
		public function updateTaskAndMessageFromMove(newBoxID:uint, newMailboxName:String, lastMailboxName:String, mailMessageGUID:String, messageID:String):void
		{
			//get the task
			var msgInfo:Object = getMailMessageInfo(mailMessageGUID);
			var task:FullTask = FlexGlobals.topLevelApplication.organizeBoxManager.getSpecificTask( msgInfo.taskGUID );
			//move the task
			FlexGlobals.topLevelApplication.organizeBoxManager.putTaskInOrganizeBox(task,newBoxID,false);
			moveEmailMessagesWithTask(task, false);			
		}
		
		public function getMessages(type:String):Array
		{
			sql = new SQLStatement();
			sql.text = "SELECT * FROM mailmessage WHERE userGUID=:UserGUID AND lastMailboxName=:LastMailboxName " +
				"ORDER BY subject ";
			sql.parameters[":UserGUID"] = _userGUID;
			sql.parameters[":LastMailboxName"] = type;
			sql.itemClass = IMFMessage;
			DB.doSQL(sql);
			
			return sql.getResult().data;
		}
		
		public function getAttachments(taskGUID:String):Array
		{
			var sql:SQLStatement = new SQLStatement();
			sql.text = "SELECT * FROM attachment WHERE taskGUID=:TaskGUID";
			sql.parameters[":TaskGUID"] = taskGUID;
			sql.itemClass = AttachmentVO;
			DB.doSQL(sql);
			
			return sql.getResult().data;
			
		}
		
		public function addTaskAttachment(attach:AttachmentVO):String
		{
			var sql:SQLStatement = new SQLStatement();
			attach.attachmentGUID = System.newGUID();
			attach.userGUID = _userGUID;
			sql.text = "INSERT INTO attachment " + 
				"(attachmentGUID, taskGUID, userGUID, sourcepath, storepath, title, filetype " + 
				", sha1digest, isManaged, sourceType, haveData " + 
				", dateCreated, dateModified) " + 
				"VALUES (" + 
				":AttachmentGUID, :TaskGUID, :UserGUID, :Sourcepath, :Storepath, :Title, :Filetype " + 
				", :Sha1digest, :IsManaged, :SourceType, :HaveData " + 
				", strftime('%s','now'), strftime('%s','now') )";
			
			sql.parameters[":AttachmentGUID"] = attach.attachmentGUID;
			sql.parameters[":TaskGUID"] = attach.taskGUID;
			sql.parameters[":UserGUID"] = attach.userGUID;
			sql.parameters[":Sourcepath"] = attach.sourcepath;  
			sql.parameters[":Storepath"] = attach.storepath;
			sql.parameters[":Title"] = attach.title;
			sql.parameters[":Filetype"] = attach.filetype;
			sql.parameters[":Sha1digest"] = attach.sha1digest;
			sql.parameters[":IsManaged"] = attach.isManaged;
			sql.parameters[":SourceType"] = attach.sourceType;
			sql.parameters[":HaveData"] = attach.haveData;
			
			DB.doSQL(sql);
			
			if(attach.isManaged)
			{	//generate the managed filename and update the entry
				
				attach.storepath = attach.storepath + attach.attachmentGUID + '.hel.' + attach.filetype;
				
				sql.clearParameters();
				sql.text = "UPDATE attachment SET storepath=:storepath WHERE attachmentGUID=:attachmentGUID ";
				sql.parameters[":attachmentGUID"] = attach.attachmentGUID;
				sql.parameters[":storepath"] = attach.storepath;
				
				DB.doSQL(sql);
			}
			
			return attach.attachmentGUID;
		}
		
		public function moveMessages(msgIds:Array, target:String):void
		{
			for each(var msgId:String in msgIds)
			{
				var sql:SQLStatement = new SQLStatement();			
				sql.text = 'UPDATE mailmessage SET lastMailboxName=:lastMailboxName WHERE messageID=:messageID';
				sql.parameters[":lastMailboxName"] = target;
				sql.parameters[":messageID"] = msgId;
				DB.doSQL(sql);
			}
		}		
	}	
}