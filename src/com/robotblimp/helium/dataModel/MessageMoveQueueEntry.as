package com.robotblimp.helium.dataModel
{
	import com.hurlant.util.der.Integer;
	import com.robotblimp.helium.services.db.Database;
	
	import flash.data.SQLStatement;

	public class MessageMoveQueueEntry
	{
		public var queueID:Number;
		public var mailMessageGUID:String;
		public var messageID:String;
		public var profileGUID:String;
		public var profileType:int;
		public var lastMailboxName:String;
		public var lastOrganizeBox:int;
		public var targetMailboxName:String;
		public var targetOrganizeBox:int;
		
		public function MessageMoveQueueEntry()
		{
		}
		
		public function saveToQueue(userGUID:String, DB:Database):void
		{
			var sql:SQLStatement = new SQLStatement();
			sql.text = "INSERT INTO mailmovequeue " +
				"(userGUID, mailMessageGUID, messageID, profileGUID, profileType, lastMailboxName, lastOrganizeBox " +
				", targetMailboxName, targetOrganizeBox, timeQueued) " +
				"VALUES " +
				"(:UserGUID, :MailMessageGUID, :MessageID, :ProfileGUID, :ProfileType, :LastMailboxName, :LastOrganizeBox " +
				", :TargetMailboxName, :TargetOrganizeBox, strftime('%s','now') ) ";
			sql.parameters[":UserGUID"] = userGUID;
			sql.parameters[":MailMessageGUID"] = mailMessageGUID;
			sql.parameters[":MessageID"] = messageID;
			sql.parameters[":ProfileGUID"] = profileGUID;
			sql.parameters[":ProfileType"] = profileType;
			sql.parameters[":LastMailboxName"] = lastMailboxName;
			sql.parameters[":LastOrganizeBox"] = lastOrganizeBox;
			sql.parameters[":TargetMailboxName"] = targetMailboxName;
			sql.parameters[":TargetOrganizeBox"] = targetOrganizeBox;
			DB.doSQL(sql);
			queueID = sql.getResult().lastInsertRowID; //in case we need some ID
		}
	}
}