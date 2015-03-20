package com.robotblimp.helium.services.msg
{
	import com.adobe.serialization.json.*;
	import com.hurlant.util.Base64;
	import com.robotblimp.helium.constants.*;
	import com.robotblimp.helium.core.*;
	import com.robotblimp.helium.dataModel.*;
	import com.robotblimp.helium.dataModel.profileClasses.IMAPProfileVO;
	import com.robotblimp.helium.events.FormEvent;
	import com.robotblimp.helium.services.db.*;
	
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	public class IMAPChecker extends EventDispatcher
	{
		private var _userGUID:String;
		private var _password:String;
		private var _deviceUID:String;
		
		private var DB:Database;
		private var sql:SQLStatement;
		
		private var REST0:HTTPService;
		private var REST1:HTTPService;
		private var REST2:HTTPService;
		
		
		
		public function IMAPChecker(userGUID:String, password:String, deviceUID:String)
		{
			DB = FlexGlobals.topLevelApplication.Sys.DB;
			_userGUID = userGUID;
			_password = password;
			_deviceUID = deviceUID;
			
			REST0 = new HTTPService();
			REST0.resultFormat = HTTPService.RESULT_FORMAT_TEXT;
			REST0.method = "POST";
			REST0.addEventListener(ResultEvent.RESULT, RESTResultHandler);	
			REST0.addEventListener(FaultEvent.FAULT, RESTFaultHandler);			
			REST0.url = Helium.centralURL_IMAP;
			
		}

		public function set password(pass:String):void
		{
			_password = pass;
		}
		
		public function checkProfilesBoxes():void
		{
			var app:Helium = (FlexGlobals.topLevelApplication as Helium);
			
			//var messageIDs:Array = app.msgManager.getMessageIDs(); //we already have these, don't download them again please
			
			//each profile
			var json:String;
			var profiles:Array = app.US.IMAPProfiles;
			for each(var IP:IMAPProfileVO in profiles){
				if(IP.enabled){
					var payload:Object = {
								"action"		:"checkIMAP"
								,"userGUID"		:_userGUID
								,"pass"		:_password
								,"msgIDs"		:app.msgManager.getProfileMessageIDs(IP.profileGUID)
								,"profileGUID"	:IP.profileGUID
								,"imap_username":IP.username
								,"imap_password":IP.password
								,"imap_server"	:IP.server
								,"imap_port"	:IP.port
								,"imap_encrypt"	:IP.encrypt
								,"checkBoxes":{} // the list of mailboxes to check for messages
								
								
					};
					
					//get now messages
					if(IP.boxNow){
						payload.checkBoxes[IP.boxNow] = {'mailbox':IP.boxNow,'boxID': box_constants.BOX_NOW};						
					} 
					if(IP.boxSomeday){
						payload.checkBoxes[IP.boxSomeday] = {'mailbox':IP.boxSomeday,'boxID': box_constants.BOX_SOMEDAY};						
					}
					if(IP.boxScheduled){
						payload.checkBoxes[IP.boxScheduled] = {'mailbox':IP.boxScheduled,'boxID': box_constants.BOX_SCHEDULED};						
					}
					if(IP.boxWaitingOn){
						payload.checkBoxes[IP.boxWaitingOn] = {'mailbox':IP.boxWaitingOn,'boxID': box_constants.BOX_WAITINGON};
					} 
					if(IP.boxArchive){
						payload.checkBoxes[IP.boxArchive] = {'mailbox':IP.boxArchive,'boxID': box_constants.BOX_ARCHIVE};
					} 
					
					json = JSON.encode(payload);
					REST0.send( {jsn: json} ); 
					(FlexGlobals.topLevelApplication as Helium).addNetActivityIndication("IMAPChecker:checkProfilesBoxes0");	
							
				}
import com.robotblimp.helium.core.ProjectManager;

import mx.core.FlexGlobals;

			}		
		}
		
		private function RESTFaultHandler(event:FaultEvent):void
		{
			trace(event.message);
		}
		
		private function RESTResultHandler(result:ResultEvent ):void
		{
			(FlexGlobals.topLevelApplication as Helium).removeNetActivityIndication();
			//route messages
			
			var res:Object;
			
			try{
			 	res = JSON.decode(result.message.body.toString());
			}
			catch(err:Error){
				trace("IMAP result: " + result.message.body.toString());
				res = {res:'notauth'};
			}
			
			if('notauth'==res.res)
			{	
				dispatchEvent( new FormEvent("CENTRAL_NotAuthorized",{action:res.action}));
			}
			else
			{
				if('checkIMAP'==res.action)
				{
					saveIMAPMessages(res);		
				}
				else if('getIMAPAttachment'==res.action)
				{
					saveAttachment(res);
				}
				else if('moveGroupedMessages'==res.action)
				{
					trace("moved messages?");
				}
			}
		}
		
		private function getFiletype(attach:Object):String
		{
			//{"ext":"MSWORD","fpos":5,"data":"","subtype":"msword","filename":"Mon, 08 Feb 2010 23:05:21 GMT","byteCount":14714,"type":"application/msword"}
			var known:Object =
			{'JPEG':'.jpg','PNG':'.png','MSWORD':'.doc','PDF':'.pdf','RTF':'.rtf'};
			
			if(known[(attach.ext as String).toUpperCase()])
				return known[(attach.ext as String).toUpperCase()];
			
			return '.txt';	
		}
		
		private function saveIMAPMessages(res:Object):void
		{
			var boxID:int = int(res.imap_boxID);
			var msgBundle:Object;
			var task:FullTask;
			var ft:FullTask;					
			var attach:Object;
			
			var updateTasks:ArrayCollection = new ArrayCollection(); //holds temporary fullTasks for updating current view
			var CDOM:CoreDataObjectManager = FlexGlobals.topLevelApplication.CDOM;
			var organizeBoxManager:OrganizeBoxManager = FlexGlobals.topLevelApplication.organizeBoxManager;
			var projectManager:ProjectManager = FlexGlobals.topLevelApplication.projectManager;
			var msgManager:MessageManager = FlexGlobals.topLevelApplication.msgManager;
			var US:UserSettings = FlexGlobals.topLevelApplication.US;
			
			//	$res['msgs'] = array('moved'=>$moved,'news'=>$news,'unfound'=>$unfound);
			//	moved:{boxName:{mailbox:{mailbox, boxID}, msgs:[{mailMessageGUID, messageID, lastMailboxName}]} }
			//	unfound:[{mailMessageGUID, messageID, lastMailboxName}]
			//	news:{boxName:{mailbox:{mailbox,boxID}, msgs:{[messageID:{head,parts}]} }
			
			var msgBoxName:String;
			var mailbox:Object;
			var msgs:Object;
			
			//handle moved messages
			var moved:Object = res.msgs.moved;
			for(msgBoxName in moved){
				mailbox = moved[msgBoxName].mailbox; //boxID, mailbox
				msgs = moved[msgBoxName].msgs;
				for each(var mm:Object in msgs){ // movedMessage = {lastMailboxName, mailMessageGUID, messageID
					//move the associated task etc.
					msgManager.updateTaskAndMessageFromMove(mailbox.boxID, mailbox.mailbox, mm.lastMailboxName, mm.mailMessageGUID, mm.messageID);					
				}
			}
			
			//handle unfound messages
			var unfound:Object = res.msgs.unfound;
			
			//handle new messages
			var msgBoxes:Object = res.msgs.news;
			
			for(msgBoxName in msgBoxes)
			{ //each message bundle
				mailbox = msgBoxes[msgBoxName].mailbox;
				msgs = msgBoxes[msgBoxName].msgs;
				for(var msgID:String in msgs)
				{ //each message bundle
					msgBundle = msgs[msgID];						
					var msg:IMFMessage =  new IMFMessage();
					
					//make sure that no task exists for this msgID
					var msgInfo:Object = msgManager.getMessageInfo( msgID );
					
					if(msgInfo && null != msgInfo.taskGUID) //it's been seen
					{
						continue;
					}
					
					var msgParts:Object 	= msgBundle.parts;
					var contentParts:Array 	= msgParts.subparts;
					
					msg.attachments	= msgParts.attachments;
					msg.subject = msgBundle.head.subject;
					msg.fromAddress = msgBundle.head.from;
					msg.toAddress = msgBundle.head['to'];
					msg.messageID = msgBundle.head.message_id;
					msg.messageIMAPNum = msgBundle.head.msgno;
					msg.messageDate = msgBundle.head.date;
					
					if(0<contentParts.length){
						for each(var altMsg:Object in contentParts){
			  				if(altMsg.plain && ''!=altMsg.plain) msg.bodyText = altMsg.plain;
			  				if(altMsg.html && ''!=altMsg.html) msg.bodyHTML = altMsg.html;
			  			}
			  		}
			  		else {
			  			if(contentParts.plain && ''!=contentParts.plain) msg.bodyText = contentParts.plain;
			  			if(contentParts.html && ''!=contentParts.html) msg.bodyHTML = contentParts.html;			  			
			  		}		
			  		
			  		if(msgParts.plain && ''!=msgParts.plain) msg.bodyText = msgParts.plain;
		  			if(msgParts.html && ''!=msgParts.html) msg.bodyHTML = msgParts.html;
		  				
					//make a task 
					task = new FullTask();
					task.title = (msg.subject && msg.subject!="") ? msg.subject : "(no subject)";
		  			task.organizeBox = uint(mailbox.boxID);
		  			task.source = Source.IMAP;
					task.sourceProfileGUID = res.profileGUID;
		  			
		      		//create the task in the DB
		      		CDOM.createNewTask(task);
		      		organizeBoxManager.putTaskInOrganizeBox(task, task.organizeBox);
		  			projectManager.addTaskToProject(projectManager.NoProjectGUID, task.taskGUID);
					task.projectGUID = projectManager.NoProjectGUID;
		  			
		  			//create note with plain text content
		  			var n:TaskNote = new TaskNote();
					n.taskGUID = task.taskGUID;  
					n.title = (msg.subject && msg.subject!="") ? msg.subject : "(no subject)";
					
					if(msg.bodyHTML && ''!=msg.bodyHTML)
						n.content = msg.bodyHTML;
					else if(msg.bodyText && ''!=msg.bodyText)
						n.content = msg.bodyText;	
					//save to the DB
					n.noteGUID = CDOM.addTaskNote(n);
	  			
					//save task message
					var mailMessageGUID:String = msgManager.storeTaskMessage(task.taskGUID, n.noteGUID, res.profileGUID, mailbox.mailbox, task.organizeBox, msg );
				
					//attachments
					for each(attach in msg.attachments)
					{
						trace(JSON.encode(attach));
						var attachmentVO:AttachmentVO = new AttachmentVO();
						attachmentVO.taskGUID = task.taskGUID;
						attachmentVO.userGUID = _userGUID;
						attachmentVO.filetype = getFiletype(attach);
						attachmentVO.haveData = false;
						attachmentVO.isManaged = false;
						attachmentVO.sha1digest = "email";
						attachmentVO.sourcepath = attach.fpos;
						attachmentVO.storepath = "IMAP";
						attachmentVO.mailMessageGUID = mailMessageGUID;
						attachmentVO.title = attach.filename;
						attachmentVO.sourceType = Source.IMAP;
						//add attachment
						CDOM.addTaskAttachment(attachmentVO);				
					}
					
					//automerge ?
					var didMerge:Boolean;
					if(US.autoMergeTasks){
						didMerge = CDOM.mergeTaskIfDuplicate(task, US.ignoreSubjectPrefixes); //if a merge happens, task will be changed to the previously existing task
					} 
					//only add to updateTasks if it didn't merge
					if(!didMerge || !US.autoMergeTasks){
						task.reloadAll(FlexGlobals.topLevelApplication.Sys.DB);
						updateTasks.addItem( task ); //a fullTask
					}
					
					msgBundle = null;
				}
			}
			if(0<updateTasks.length) //will be null if no messages
			{
				var notify:String = updateTasks.length + " NEW " + box_constants.BOX_ID_TITLE(boxID).toUpperCase() + " TASK";
				if(1<updateTasks.length)
					notify += "S";
				notify += " FROM IMAP";
				FlexGlobals.topLevelApplication.showNotification(notify,null);
			}	
			if(boxID == FlexGlobals.topLevelApplication.currentDisplay.Box) //currently looking at the box the message goes in
			{
				
		/*	//should add the tasks to under their correct header(s)
				for each(ft in updateTasks) //only one item
				{
					FlexGlobals.topLevelApplication.organizeBoxTaskGroups.addItemAt( ft ,1);
				}
		*/
				//just update the whole display					
				FlexGlobals.topLevelApplication.showBoxTasks( boxID );
			}
			
			if( box_constants.BOX_NOW == boxID) //update the Now counter
			{
				FlexGlobals.topLevelApplication.updateNowCounts();
			}
		
		}
		
		private function saveAttachment(res:Object):void
		{
			var storepath:String = FlexGlobals.topLevelApplication.US.managedFileLocation.nativePath;
			storepath += File.separator + res.attachmentGUID + '.hel' + res.filetype;
			//base64 decode to file
			var file:File = new File(storepath);
			var fileStream:FileStream = new FileStream();
			fileStream.open(file,FileMode.WRITE);
			var regRN:RegExp = /\r\n/g;
			var dataS:String = (res.data as String).replace(regRN,'');
			fileStream.writeBytes( Base64.decodeToByteArray(dataS) );
			
			//fileStream.writeUTFBytes( Base64.decode( res.data ) ); 
			fileStream.close();
			
			//update the attachment
			sql = new SQLStatement();
			sql.text = "UPDATE attachment SET " + 
					"storepath=:Storepath, isManaged=1, haveData=1 " +
					",dateModified=strftime('%s','now') " + 
					"WHERE attachmentGUID=:AttachmentGUID";
			sql.parameters[":Storepath"] = storepath;
			sql.parameters[":AttachmentGUID"] = res.attachmentGUID;
			DB.doSQL(sql);
						
			dispatchEvent(new FormEvent('ATTACHMENT_DOWNLOAD_COMPLETE',{path:storepath, source:'IMAP'}));	
		}
		
		public function getAttachment(attachment:AttachmentVO):void
		{
			var msgManager:MessageManager = FlexGlobals.topLevelApplication.msgManager;
			var msgInfo:Object = msgManager.getMailMessageInfo( attachment.mailMessageGUID );
			var IP:IMAPProfileVO = FlexGlobals.topLevelApplication.US.getIMAPProfile(msgInfo.profileGUID);
			
			var payload:Object = {
						"action"		:"getIMAPAttachment"
						,"userGUID"		:_userGUID
						,"pass"		:_password
						,"profileGUID"	:IP.profileGUID
						,"imap_username":IP.username
						,"imap_password":IP.password
						,"imap_server"	:IP.server
						,"imap_port"	:IP.port
						,"imap_encrypt"	:IP.encrypt
						,"imap_box"		: msgInfo.lastMailboxName
						,"fpos"			: attachment.sourcepath
						,"message_id"	: msgInfo.messageID
						,"attachmentGUID"	: attachment.attachmentGUID
						,"filetype"		: attachment.filetype
						
			};
			
			var json:String = JSON.encode(payload);
			trace("IMAP sending: " + json);
			trace(REST0.url);
			REST0.send( {jsn: json} ); 
			(FlexGlobals.topLevelApplication as Helium).addNetActivityIndication("IMAPChecker:GetAttachment");	
		
		}

		public function moveQueuedMessages():void
		{			
			//get the queued messages
			sql = new SQLStatement();
			sql.text = "SELECT profileGUID, mailMessageGUID, messageID, lastMailboxName, targetMailboxName " +
				"FROM mailmovequeue " +
				"WHERE profileType IN (" + [UserSettings.Profile_GMail, UserSettings.Profile_MobileMe, UserSettings.Profile_IMAP].join(',') + ") " +
				"AND userGUID=:UserGUID " +
				"ORDER BY profileGUID, timeQueued "; //only order by time queued, since in theory the same message could have been moved a few times offline
			sql.parameters[":UserGUID"] = _userGUID;
			sql.itemClass = MessageMoveQueueEntry;
			DB.doSQL(sql);
			var res:SQLResult = sql.getResult();
			
			if(res.data){
				
				var queue:Array = [];
				var profileGroups:Object = {};
				for(var i:uint =0; i<res.data.length;i++){
					var mmqe:MessageMoveQueueEntry = res.data[i] as MessageMoveQueueEntry;
					if(!profileGroups[mmqe.profileGUID]){
						profileGroups[mmqe.profileGUID] = {};
						var IP:IMAPProfileVO = FlexGlobals.topLevelApplication.US.getIMAPProfile( mmqe.profileGUID );
						profileGroups[mmqe.profileGUID].profileGUID = IP.profileGUID;
						profileGroups[mmqe.profileGUID].imap_username = IP.username;
						profileGroups[mmqe.profileGUID].imap_password = IP.password;
						profileGroups[mmqe.profileGUID].imap_server = IP.server;
						profileGroups[mmqe.profileGUID].imap_port = IP.port;
						profileGroups[mmqe.profileGUID].imap_encrypt = IP.encrypt;
						profileGroups[mmqe.profileGUID].messages = [];
					} 
					
					profileGroups[mmqe.profileGUID].messages.push(
						{
							"mailMessageGUID" : mmqe.mailMessageGUID
							,"messageID" : mmqe.messageID
							,"lastMailboxName" : mmqe.lastMailboxName
							,"targetMailboxName" : mmqe.targetMailboxName													
						}
						);
				}
				
				var payload:Object = {
					"action"		:"moveGroupedMessages"
					,"userGUID"		:_userGUID
					,"pass"		:_password
					,"groupedMessages" : profileGroups
				}
				var json:String = JSON.encode(payload);
				REST0.send( {jsn: json} );	
					
				
			}
		}
	}
}