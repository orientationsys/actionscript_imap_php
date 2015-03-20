package com.robotblimp.helium.dataModel
{
	import com.robotblimp.helium.services.db.Database;
	
	import flash.data.SQLStatement;
	
	public class AttachmentVO
	{
		public var	attachmentGUID:String;
		public var	taskGUID:String;
		public var	userGUID:String;
		public var	sourcepath	:String;
		public var	storepath	:String;
		public var	title	:String;
		public var	filetype	:String;
		public var	sha1digest	:String;
		public var	isManaged	:Boolean;
		public var	sourceType	:uint;
		public var	haveData	:Boolean;
		public var	dateCreated	:Number;
		public var	dateModified	:Number;
		
		public function AttachmentVO()
		{
		}
		
		public function update(DB:Database):void
		{		
			var sql:SQLStatement = new SQLStatement();
			sql.text = "UPDATE attachment SET " + 
					"sourcepath=:Sourcepath, storepath=:Storepath, title=:Title, filetype=:Filetype " + 
					", sha1digest=:Sha1digest, isManaged=:IsManaged, sourceType=:SourceType " + 
					", haveData=:FaveData ,dateModified=strftime('%s','now') " + 
					"WHERE attachmentGUID=:AttachmentGUID";
			
			sql.parameters[":Sourcepath"] = sourcepath;  
			sql.parameters[":Storepath"] = storepath;
			sql.parameters[":Title"] = title;
			sql.parameters[":Filetype"] = filetype;
			sql.parameters[":Sha1digest"] = sha1digest;
			sql.parameters[":IsManaged"] = isManaged;
			sql.parameters[":SourceType"] = sourceType;
			sql.parameters[":HaveData"] = haveData;
			sql.parameters[":AttachmentGUID"] = attachmentGUID;
			
			DB.doSQL(sql);
			
		}
	}
}