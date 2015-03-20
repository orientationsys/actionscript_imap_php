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
	
	import flash.data.SQLStatement;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.core.FlexGlobals;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	public class ExchangeStore extends EventDispatcher
	{
		private var DB:Database;
		private var sql:SQLStatement;
		
		private var _userGUID:String;
		private var _deviceID:String;
		private var _password:String;
		private var _centralURL:String;
		private var REST0:HTTPService;
		
		private var _centralUserGUID:String;
		private var _centralPash:String;
		
		public function ExchangeStore(userGUID:String, password:String, deviceUID:String)
		{
			DB = FlexGlobals.topLevelApplication.Sys.DB;
			
			var app:Helium = FlexGlobals.topLevelApplication as Helium;
			_userGUID = userGUID;
			_password = password;
			_deviceID = deviceUID;
			
			REST0 = new HTTPService();
			REST0.resultFormat = HTTPService.RESULT_FORMAT_TEXT;
			REST0.method = "POST";
			REST0.showBusyCursor = true;
			REST0.addEventListener(ResultEvent.RESULT, RESTResultHandler);
			REST0.addEventListener(FaultEvent.FAULT, RESTFaultHandler);
			REST0.url = Helium.centralURL_Exchange;
		}

		public function moveTaskMessageToBox(msgArr:Object, destination:String ):void
		{
			//get task message href if there is one
/*			sql = new SQLStatement();
			sql.text = "SELECT messageID FROM mailmessage";
			DB.doSQL(sql);
			
			var mIDs:Array = sql.getResult().data;
			var app:Helium = FlexGlobals.topLevelApplication as Helium;
			
			var msgInfo:Object = app.msgManager.getTaskMessageInfo(taskGUID);
			var EP:ExchangeProfileVO = app.US.getExchangeProfile(msgInfo.profileGUID);
			
			if(EP.enabled){
				var payload:Object = {"action" 		: "moveExchangeMessage"
									,"userGUID"		: app.ugManager.userGUID
 									,"pass"			: app.GS.lastPassword							
 									,"profileGUID"	: EP.profileGUID
 									,"exch_username": EP.username
 									,"exch_password": EP.password
 									,"exch_server"	: EP.server
 									,"exch_protocol": EP.protocol
 									,"exch_version"	: EP.version
 									,"exch_domain"	: EP.domain
 									,"exch_mailbox"	: EP.mailbox
 									,"exch_authdest": EP.authdest 									
									};
				
				//
				payload["exch_box"] = EP.boxNow;
				payload["exch_boxID"] = boxID;
				payload["targetURI"] = "@Someday/Attachment.EML";
				payload["destinationURI"] = "@Now/Attachment.EML";
				
				//post it	
				var json:String = JSON.encode(payload);
				trace("sending: " + json);
				trace(REST0.url);
				REST0.send( {jsn: json} );
				(FlexGlobals.topLevelApplication as Helium).addNetActivityIndication("ExchangeStore:moveTaskMessageToBox");	
			
			}*/
			
			var app:Helium = FlexGlobals.topLevelApplication as Helium;
			var profiles:Array = app.US.ExchangeProfiles;
			for each(var EP:ExchangeProfileVO in profiles){
				if(EP.enabled){			
					var msgSubjects:Array = new Array();
					var msgIDs:Array = new Array();
					for each(var msg:IMFMessage in msgArr)
					{
						msgSubjects.push(msg.subject);
						msgIDs.push(msg.messageID);
					}
					var target:String = msgArr[0].lastMailboxName;
					var payload:Object = {
						"action"		:"moveExchangeMessage"
						,"userGUID"		:_userGUID
						,"pass"		:_password
						,"targetURI":target
						,"destinationURI":destination
						,"subjects": msgSubjects
						,"msgIDs": msgIDs
						,"profileGUID"	:EP.profileGUID
							,"exch_username": EP.username
							,"exch_password": EP.password
							,"exch_server"	: EP.server
							,"exch_protocol": EP.protocol
							,"exch_version"	: EP.version
							,"exch_domain"	: EP.domain
							,"exch_mailbox"	: EP.mailbox
							,"exch_authdest": EP.authdest
							
					};
					if(msgArr[0].lastMailboxName == '@Now')
					{
						payload['exch_box'] = EP.boxNow;
						payload['exch_boxID'] = box_constants.BOX_NOW;
					}
					else if(msgArr[0].lastMailboxName == "@Someday")
					{
						payload['exch_box'] = EP.boxSomeday;
						payload['exch_boxID'] = box_constants.BOX_SOMEDAY;							
					}
					var json:String = JSON.encode(payload);
					REST0.send( {jsn: json} );	
				}				
			}
			(FlexGlobals.topLevelApplication as Helium).addNetActivityIndication("ExchangeStore:moveTaskMessageToBox");			
		}
		private function RESTFaultHandler(result:FaultEvent ):void
		{
			trace("REST fault:" + result.message.body.toString());
		}
		private function RESTResultHandler(result:ResultEvent ):void
		{
			(FlexGlobals.topLevelApplication as Helium).removeNetActivityIndication();
			//route messages
			trace(result.message.body.toString());
			var res:Object;
			try{
			 	res = JSON.decode(result.message.body.toString());
			}
			catch(err:Error){
				trace("Cloud result: " + result.message.body.toString());
				res = {res:'notauth'};
			}
			if('notauth'==res.res)
			{	
				dispatchEvent( new FormEvent("CENTRAL_NotAuthorized",{action:res.action}));
			}
			else
			{
				if('moveExchangeMessage'==res.action)
				{					
					FlexGlobals.topLevelApplication.msgManager.moveMessages(res.msgIDs, res.destinationURI);
					FlexGlobals.topLevelApplication.refreshMessageList(res.targetURI);
					FlexGlobals.topLevelApplication.refreshMessageList(res.destinationURI);
				}
			}
		}
	}
}