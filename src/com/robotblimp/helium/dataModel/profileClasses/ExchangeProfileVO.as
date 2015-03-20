package com.robotblimp.helium.dataModel.profileClasses
{
	import com.robotblimp.helium.constants.box_constants;
	import com.robotblimp.helium.services.db.*;
	
	import flash.data.EncryptedLocalStore;
	import flash.data.SQLStatement;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	import mx.core.FlexGlobals;
	
	public class ExchangeProfileVO extends ProfileVO
	{
		public var exchangeProfileGUID:String;
		public var username:String;
		public var password:String;
		public var domain:String;
		public var mailbox:String;
		public var authdest:String;
		public var server:String;
		public var protocol:String;
		public var version:String;
		public var boxNow:String = "@Now";
		public var boxScheduled:String = "@Scheduled";
		public var boxWaitingOn:String = "@Waiting On";
		public var boxSomeday:String = "@Someday";
		public var boxArchive:String = "@Archive";

		
		public function ExchangeProfileVO()
		{
			super();
		}

		override public function update(DB:Database):void
		{
			super.update(DB);
			
			var sql:SQLStatement = new SQLStatement();
			sql.text = "UPDATE exchangeprofile " + 
					"SET username=:Username, domain=:Domain, mailbox=:Mailbox, authdest=:Authdest " + 
					", server=:Server, protocol=:Protocol, version=:Version, boxNow=:BoxNow, boxScheduled=:BoxScheduled " + 
					", boxWaitingOn=:BoxWaitingOn, boxSomeday=:BoxSomeday, boxArchive=:BoxArchive " + 
					"WHERE exchangeProfileGUID=:ExchangeProfileGUID ";
			sql.parameters[":Username"] = username;
			sql.parameters[":Domain"] = domain;
			sql.parameters[":Mailbox"] = mailbox;
			sql.parameters[":Authdest"] = authdest;
			sql.parameters[":Server"] = server;
			sql.parameters[":Protocol"] = protocol;
			sql.parameters[":Version"] = version;
			sql.parameters[":BoxNow"] = boxNow;
			sql.parameters[":BoxScheduled"] = boxScheduled;
			sql.parameters[":BoxWaitingOn"] = boxWaitingOn;
			sql.parameters[":BoxSomeday"] = boxSomeday;
			sql.parameters[":BoxArchive"] = boxArchive;
			sql.parameters[":ExchangeProfileGUID"] = exchangeProfileGUID;
			DB.doSQL(sql);
			
			//password
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes( password );
			EncryptedLocalStore.setItem( ['profile',String(userGUID),profileGUID,'pw'].join('_') , bytes);
			
			sql.clearParameters();
			sql.text = "UPDATE externalprofile " + 
					"SET profileName=:ProfileName, enabled=:Enabled " + 
					"WHERE profileGUID=:ProfileGUID ";
			sql.parameters[":ProfileName"] = profileName;
			sql.parameters[":Enabled"] = enabled;
			sql.parameters[":ProfileGUID"] = profileGUID; 
			DB.doSQL(sql);
		}
		
		public function remove():void
		{
			var DB:Database = FlexGlobals.topLevelApplication.Sys.DB;
			var sql:SQLStatement = new SQLStatement();
			sql.text = "DELETE FROM exchangeprofile WHERE exchangeProfileGUID=:ExchangeProfileGUID ";
			sql.parameters[":ExchangeProfileGUID"] = exchangeProfileGUID;
			DB.doSQL(sql);
			
			sql.clearParameters();
			sql.text = "DELETE FROM externalprofile WHERE profileGUID=:ProfileGUID ";
			sql.parameters[":ProfileGUID"] = profileGUID;
			DB.doSQL(sql);
		}
		
		public function getMailboxNameForBox(box:uint):String
		{
			switch(box){
				case box_constants.BOX_NOW: return boxNow; break;
				case box_constants.BOX_SCHEDULED: return boxScheduled; break;
				case box_constants.BOX_WAITINGON: return boxWaitingOn; break;
				case box_constants.BOX_SOMEDAY: return boxSomeday; break;
				case box_constants.BOX_ARCHIVE: return boxArchive; break;
				default: return "";
			}
		}

	}
}