package com.robotblimp.helium.services.msg
{
	import com.adobe.serialization.json.*;
	import com.hurlant.util.Base64;
	import com.robotblimp.helium.constants.*;
	import com.robotblimp.helium.core.*;
	import com.robotblimp.helium.dataModel.*;
	import com.robotblimp.helium.dataModel.profileClasses.ExchangeProfileVO;
	import com.robotblimp.helium.events.FormEvent;
	import com.robotblimp.helium.services.db.*;
	import com.robotblimp.helium.services.log.Logger;
	
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	public class ExchangeChecker extends EventDispatcher
	{
		private var DB:Database;
		private var sql:SQLStatement;
		
		private var _userGUID:String;
		private var _password:String;
		private var _deviceID:String;
		private var REST0:HTTPService;
		private var REST1:HTTPService;
		private var REST2:HTTPService;
		private var logger:Logger;
		private var testCredsFunction:Function;
		private var testCredsProfile:Object;
		
		public function ExchangeChecker(userGUID:String, password:String, deviceUID:String)
		{
			DB = FlexGlobals.topLevelApplication.Sys.DB;
			
			logger = new Logger();
			_userGUID = userGUID;
			_password = password;
			_deviceID = deviceUID;
			
			REST0 = new HTTPService();
			REST0.resultFormat = HTTPService.RESULT_FORMAT_TEXT;
			REST0.method = "POST";
			REST0.showBusyCursor = true;
			REST0.addEventListener(ResultEvent.RESULT, RESTResultHandler);
			REST0.url = Helium.centralURL_Exchange;
			
			REST1 = new HTTPService();
			REST1.resultFormat = HTTPService.RESULT_FORMAT_TEXT;
			REST1.method = "POST";
			REST1.addEventListener(ResultEvent.RESULT, RESTResultHandler);
			REST1.url = Helium.centralURL_Exchange;
			
			REST2 = new HTTPService();
			REST2.resultFormat = HTTPService.RESULT_FORMAT_TEXT;
			REST2.method = "POST";
			REST2.addEventListener(ResultEvent.RESULT, RESTResultHandler);
			REST2.url = Helium.centralURL_Exchange; 
		}
	
		public function set password(pass:String):void
		{
			_password = pass;
		}
	
		public function destruct():void
		{
			REST0.removeEventListener(ResultEvent.RESULT, RESTResultHandler);
			REST0.cancel();
			REST1.removeEventListener(ResultEvent.RESULT, RESTResultHandler);
			REST1.cancel();
			REST2.removeEventListener(ResultEvent.RESULT, RESTResultHandler);
			REST2.cancel();
		}
	
		private function testCredCallback(valid:Boolean,profile:Object):void{}
		
		public function testCredentials(profile:ExchangeProfileVO, callback:Function):void
		{
			//get messageIDs	
			var app:Helium = (FlexGlobals.topLevelApplication as Helium);
	
			testCredsFunction = callback;
			testCredsProfile = profile;
			
			var payload:Object = {"action" 		: "testCredentials"
							,"userGUID"		: _userGUID
 							,"pass"			: _password
 							,"profileGUID"	: profile.profileGUID
 							,"exch_username": profile.username
 							,"exch_password": profile.password
 							,"exch_server"	: profile.server
 							,"exch_protocol": profile.protocol
 							,"exch_version"	: profile.version
 							,"exch_domain"	: profile.domain
 							,"exch_mailbox"	: profile.mailbox
 							,"exch_authdest": profile.authdest
							};
			//post it	
			var json:String = JSON.encode(payload);
			REST0.send( {jsn: json} );
			app.addNetActivityIndication("ExchangeChecker:testCredentials");
	
	
		}
		private function handleTestCredentials(res:Object):void
		{
			testCredsFunction(Boolean(res.res), testCredsProfile);
		}
		
		private function checkAuthenticatedBoxes(isAuthenticated:Boolean, profile:ExchangeProfileVO):void
		{
			var app:Helium = FlexGlobals.topLevelApplication as Helium;
			if(!isAuthenticated) //disable the profile
			{
				profile.enabled = false;
				profile.userGUID = _userGUID;
				profile.update( FlexGlobals.topLevelApplication.Sys.DB);
				app.showNotification("Couldn't sign in to " + profile.profileName + ". Check your credentials!");
			}
			else
			{
				
				var messageIDs:Array = app.msgManager.getMessageIDs(); //we already have these, don't download them again please
				var payload:Object = {"action" 		: "checkExchange"
								,"userGUID"		: _userGUID
	 							,"pass"			: _password
	 							,"msgIDs"		: messageIDs
	 							,"profileGUID"	: profile.profileGUID
	 							,"exch_username": profile.username
	 							,"exch_password": profile.password
	 							,"exch_server"	: profile.server
	 							,"exch_protocol": profile.protocol
	 							,"exch_version"	: profile.version
	 							,"exch_domain"	: profile.domain
	 							,"exch_mailbox"	: profile.mailbox
	 							,"exch_authdest": profile.authdest
								};
			
				var json:String;
				
				//get @Now messages
				if(profile.boxNow && ''!=profile.boxNow)
				{
					payload["exch_box"] = profile.boxNow;
					payload["exch_boxID"] = box_constants.BOX_NOW;
					//post it	
					json = JSON.encode(payload);
					REST0.send( {jsn: json} );					
					(FlexGlobals.topLevelApplication as Helium).addNetActivityIndication("ExchangeChecker:checkProfilesBoxes0");
				}
		
				//get @Someday messages
				if(profile.boxSomeday && ''!=profile.boxSomeday)
				{
					payload["exch_box"] = profile.boxSomeday;
					payload["exch_boxID"] = box_constants.BOX_SOMEDAY;
					//post it	
					json = JSON.encode(payload);
					REST0.send( {jsn: json} );
					//REST1.send( {jsn: json} );
					(FlexGlobals.topLevelApplication as Helium).addNetActivityIndication("ExchangeChecker:checkProfilesBoxes1");
				}
				
				//get @waitingon messages
				if(profile.boxWaitingOn && ''!=profile.boxWaitingOn)
				{
					payload["exch_box"] = profile.boxWaitingOn;
					payload["exch_boxID"] = box_constants.BOX_WAITINGON;
					//post it	
					json = JSON.encode(payload);
					REST0.send( {jsn: json} );
					//REST2.send( {jsn: json} );
					(FlexGlobals.topLevelApplication as Helium).addNetActivityIndication("ExchangeChecker:checkProfilesBoxes2");
				}
			}
		}
		
		public function checkProfilesBoxes():void
		{
			//get messageIDs	
			var app:Helium = (FlexGlobals.topLevelApplication as Helium);
			//get profiles
			var profiles:Array = app.US.ExchangeProfiles;
			for each(var EP:ExchangeProfileVO in profiles){
				if(EP.enabled){
					//test credentials
					testCredentials(EP,checkAuthenticatedBoxes);				
				}
			}
		}
		private function RESTResultHandler(result:ResultEvent ):void
		{
			var app:Helium = FlexGlobals.topLevelApplication as Helium;
			app.removeNetActivityIndication();
			
			//route messages
	//		trace(result.message.body.toString());
	//		logger.log(result.message.body.toString());
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
				var updateTasks:ArrayCollection = new ArrayCollection(); //holds temporary fullTasks for updating current view
				
				if('testCredentials'==res.action)
				{
					handleTestCredentials(res);
				}
				else if('checkExchange'==res.action)
				{	
					saveExchangeMessages(res);
/*					var msgs:Array = res.msgs;
					var boxID:int = int(res.exch_boxID);
					var ft:FullTask;
					var taskVO:FullTask;
					
					var orgBoxManager:OrganizeBoxManager = app.organizeBoxManager;
					var CDOM:CoreDataObjectManager = app.CDOM;
					var projectManager:ProjectManager = app.projectManager;
					var msgManager:MessageManager = FlexGlobals.topLevelApplication.msgManager;
					var US:UserSettings = app.US;
					
					sql = new SQLStatement();
					
					for each(var msgBundle:Object in msgs)
					{
						// subject, fromemail, to, message_id, plain, attachments:[]
						var attachments:Array = msgBundle.attachments;
					
						taskVO = new FullTask();
						taskVO.title = Base64.decode(msgBundle.subject);
						taskVO.status = 0;
						taskVO.startDate = 0;
						taskVO.dueDate = 0;
						taskVO.organizeBox = boxID;
						taskVO.source = Source.EXCHANGE;
						taskVO.sourceProfileGUID = res.profileGUID;
						
						//create new task	
						CDOM.createNewTask(taskVO);				
				
						//put the task in the orgBox.
						orgBoxManager.putTaskInOrganizeBox(taskVO,taskVO.organizeBox);
						//put the task in NoProject
						projectManager.addTaskToProject(projectManager.NoProjectGUID, taskVO.taskGUID);
						
						//save a note for the content
						//create a new note with the email content
						var noteVO:TaskNote = new TaskNote();
						noteVO.taskGUID = taskVO.taskGUID;
						noteVO.title = taskVO.title;
						noteVO.content = Base64.decode(msgBundle.plain);
						
						//save note
						CDOM.addTaskNote(noteVO);				
						
						//an IMFMessage object
						var msg:IMFMessage = new IMFMessage();
						
						msg.messageID = Base64.decode(msgBundle.message_id); 
						msg.subject = Base64.decode(msgBundle.subject);
						msg.fromAddress = Base64.decode(msgBundle.fromemail);
						msg.toAddress = Base64.decode(msgBundle['to']);
						msg.replyToAddress = Base64.decode(msgBundle.fromemail);
						msg.ccAddress = "cc";
						msg.bccAddress = "bcc";
						msg.messageDate = Base64.decode(msgBundle.date);
						msg.mimeVersion = "mime";
						msg.contentType = "type";
						msg.rawBodyStructure = "bodystructure";
						msg.bodyText = noteVO.content;
						
						var mailMessageGUID:String = msgManager.storeTaskMessage(taskVO.taskGUID, noteVO.noteGUID, res.profileGUID, res.exch_box, taskVO.organizeBox, msg );
													 
						// ATTACHMENTS
						for each(var attach:Object in attachments){
							//type, subtype, ext, filename, data (encoded)
							var attachment:AttachmentVO = new AttachmentVO();
							attachment.taskGUID = taskVO.taskGUID;
							attachment.userGUID = _userGUID;
							attachment.filetype = Base64.decode(attach.ext);
							attachment.haveData = false;
							attachment.isManaged = false;
							attachment.sha1digest = "email";
							attachment.sourcepath = Base64.decode(attach.href);
							attachment.storepath = "EXCHANGE";
							attachment.mailMessageGUID = mailMessageGUID;
							attachment.title = Base64.decode(attach.filename);
							attachment.sourceType = Source.EXCHANGE;
							
							//add attachment
							CDOM.addTaskAttachment(attachment);							
						}				
						
						//automerge ?
						var didMerge:Boolean;
						if(US.autoMergeTasks){
							didMerge = CDOM.mergeTaskIfDuplicate(taskVO, US.ignoreSubjectPrefixes); //if a merge happens, task will be changed to the previously existing task
						} 
						//only add to updateTasks if it didn't merge
						if(!didMerge || !US.autoMergeTasks){
							taskVO.reloadAll(app.Sys.DB);
							updateTasks.addItem( taskVO ); //a fullTask
						}
					}
					
					if(msgs.length >0)
					{
						var notify:String = updateTasks.length + " NEW " + box_constants.BOX_ID_TITLE(boxID).toUpperCase() + " TASK";
						if(1<updateTasks.length)
							notify += "S";
						notify += " FROM EXCHANGE";
						app.showNotification(notify,null);
						
						if(boxID == app.currentDisplay.Box) //currently looking at the box the message goes in
						{
							/*
							//Should add tasks under their appropriate headers
							for each(ft in updateTasks) //only one item
							{
								FlexGlobals.topLevelApplication.organizeBoxTaskGroups.addItemAt( ft ,0);
							}
							*/
/*							FlexGlobals.topLevelApplication.showBoxTasks( boxID );
						}
						
						if( box_constants.BOX_NOW == boxID) //update the Now counter
						{
							FlexGlobals.topLevelApplication.updateNowCounts();
						}
					}*/
				}
				
				else if('getExchangeAttachment'==res.action)
				{
					saveAttachment(res);
				}
			}
		}

		private function saveExchangeMessages(res:Object):void
		{			
			var boxID:int = int(res.exch_boxID);			
			var updateTasks:ArrayCollection = new ArrayCollection(); //holds temporary fullTasks for updating current view
			
			var msgManager:MessageManager = FlexGlobals.topLevelApplication.msgManager;
			for each(var msgBundle:Object in res.msgs)
			{ 
				var attachments:Array = msgBundle.attachments;
				//each message bundle						
				var msg:IMFMessage =  new IMFMessage();
				
				//make sure that we don't have this message
				var msgInfo:Object = msgManager.getMessageInfo( Base64.decode(msgBundle.message_id) );
				
				if(msgInfo && null != msgInfo.taskGUID) //it's been seen
				{
					continue;
				}
				
				msg.messageID = Base64.decode(msgBundle.message_id); 
				msg.subject = Base64.decode(msgBundle.subject);
				msg.fromAddress = Base64.decode(msgBundle.fromemail);
				msg.toAddress = Base64.decode(msgBundle['to']);
				msg.replyToAddress = Base64.decode(msgBundle.fromemail);
				msg.ccAddress = "cc";
				msg.bccAddress = "bcc";
				msg.messageDate = Base64.decode(msgBundle.date);
				msg.mimeVersion = "mime";
				msg.contentType = "type";
				msg.rawBodyStructure = "bodystructure";
				msg.bodyText = Base64.decode(msgBundle.plain);;				
				
				//save task message
				var taskGUID:String = System.newGUID();
				msgManager.storeTaskMessage( taskGUID , res.profileGUID, res.exch_box, msg );
				
				//attachments
				for each(var attach:Object in attachments)
				{					
					//type, subtype, ext, filename, data (encoded)
					var attachment:AttachmentVO = new AttachmentVO();
					attachment.taskGUID = taskGUID;
					attachment.userGUID = _userGUID;
					attachment.filetype = Base64.decode(attach.ext);
					attachment.haveData = false;
					attachment.isManaged = false;
					attachment.sha1digest = "email";
					attachment.sourcepath = Base64.decode(attach.href);
					attachment.storepath = "EXCHANGE";
					//attachment.mailMessageGUID = mailMessageGUID;
					attachment.title = Base64.decode(attach.filename);
					attachment.sourceType = 1;//Source.EXCHANGE;					
					//add attachment
					msgManager.addTaskAttachment(attachment);						
				}
				
				//update display
				updateTasks.addItem( msg ); //a fullTask
				msgBundle = null;
			}
			
			//delete db msgs which had  deleted in gmail
			//msgManager.removeMessages(res.delMsgIds, res.exch_box);	
			
			//if(0<updateTasks.length || res.delMsgIds.length > 0) //will be null if no messages
			if(0<updateTasks.length)
			{
				
				FlexGlobals.topLevelApplication.refreshMessageList(res.exch_box);
				
			}
		}
		
		private function saveAttachment(res:Object):void
		{
			var US:UserSettings = new UserSettings(_userGUID);
			
			var storepath:String = File.applicationStorageDirectory.nativePath;
			storepath += File.separator + res.attachmentGUID + '.hel' + res.filetype;
			//base64 decode to file
			var file:File = new File(storepath);
			var fileStream:FileStream = new FileStream();
			fileStream.open(file,FileMode.WRITE);
			fileStream.writeBytes( Base64.decodeToByteArray(res.data) ); 
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
						
			dispatchEvent(new FormEvent('ATTACHMENT_DOWNLOAD_COMPLETE',{path:storepath, source:'EXCHANGE'}));
		}
		
		public function getAttachment(attachment:AttachmentVO):void
		{
			//get the message info
			var msgManager:MessageManager = FlexGlobals.topLevelApplication.msgManager;
			var msgInfo:Object = msgManager.getTaskMessageInfo(attachment.taskGUID);
			var EP:ExchangeProfileVO = FlexGlobals.topLevelApplication.US.getExchangeProfile(msgInfo.profileGUID);
			
			var payload:Object = {"action" 		: "getExchangeAttachment"
								,"userGUID"		: _userGUID
 								,"pass"			: _password
 								,"profileGUID"	: EP.profileGUID
 								,"attachmentGUID"	: attachment.attachmentGUID
 								,"filetype"		: attachment.filetype
 								,"exch_username": EP.username
 								,"exch_password": EP.password
 								,"exch_server"	: EP.server
 								,"exch_protocol": EP.protocol
 								,"exch_version"	: EP.version
 								,"exch_domain"	: EP.domain
 								,"exch_box"		: msgInfo.lastMailboxName
 								,"exch_mailbox"	: EP.mailbox
 								,"exch_authdest": EP.authdest
 								,"folderAndFile": attachment.sourcepath
								};
			//post it	
			var json:String = JSON.encode(payload);
			REST0.send( {jsn: json} );
			(FlexGlobals.topLevelApplication as Helium).addNetActivityIndication("ExchangeChecker:GetAttachment");
		
		}
		
		public function moveQueuedMessages():void
		{
			//TO-DO	
		
		}
		
	}
}