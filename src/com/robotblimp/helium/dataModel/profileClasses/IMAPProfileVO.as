package com.robotblimp.helium.dataModel.profileClasses
{
	import com.robotblimp.helium.constants.box_constants;
	import com.robotblimp.helium.services.db.*;
	
	import flash.data.EncryptedLocalStore;
	import flash.data.SQLStatement;
	import flash.utils.ByteArray;
	
	import mx.core.FlexGlobals;
	
	public class IMAPProfileVO extends ProfileVO
	{
		public var imapProfileGUID:String;
		public var username:String;
		public var password:String;
		public var server:String;
		public var port:int = 993;
		public var encrypt:Boolean = true;
		public var boxNow:String = "@Now";
		public var boxScheduled:String = "@Scheduled";
		public var boxWaitingOn:String = "@Waiting On";
		public var boxSomeday:String = "@Someday";
		public var boxArchive:String = "@Archive";

		public function IMAPProfileVO()
		{
			super();
		}
		
		override public function update(DB:com.robotblimp.helium.services.db.Database):void
		{
			
			super.update(DB);
			
			var sql:SQLStatement = new SQLStatement();
			sql.text = "UPDATE imapprofile " + 
					"SET username=:Username, server=:Server " + 
					", port=:Port, encrypt=:Encrypt, boxNow=:BoxNow, boxScheduled=:BoxScheduled " + 
					", boxWaitingOn=:BoxWaitingOn, boxSomeday=:BoxSomeday, boxArchive=:BoxArchive " + 
					"WHERE imapProfileGUID=:IMAPProfileGUID ";
			sql.parameters[":Username"] = username;
			sql.parameters[":Server"] = server;
			sql.parameters[":Port"] = port;
			sql.parameters[":Encrypt"] = encrypt;
			sql.parameters[":BoxNow"] = boxNow;
			sql.parameters[":BoxScheduled"] = boxScheduled;
			sql.parameters[":BoxWaitingOn"] = boxWaitingOn;
			sql.parameters[":BoxSomeday"] = boxSomeday;
			sql.parameters[":BoxArchive"] = boxArchive;
			sql.parameters[":IMAPProfileGUID"] = imapProfileGUID;
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
			sql.text = "DELETE FROM imapprofile WHERE imapProfileGUID=:IMAPProfileGUID ";
			sql.parameters[":IMAPProfileGUID"] = imapProfileGUID;
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