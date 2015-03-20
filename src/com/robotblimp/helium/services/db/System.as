package com.robotblimp.helium.services.db
{
	
	import flash.data.SQLColumnSchema;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.desktop.NativeApplication;
	import flash.filesystem.File;
	
	import mx.utils.UIDUtil;
	
	public class System
	{
		
		private var descriptor:XML = NativeApplication.nativeApplication.applicationDescriptor;
		private var ns:Namespace = descriptor.namespaceDeclarations()[0];
		private var currentVersion:String = descriptor.ns::version;
		
		public static const DBFileName:String = "Helium.db";
		public var DB:Database = new Database(File.applicationStorageDirectory.resolvePath(DBFileName));
				
		public function System()
		{			
			createDatabase();
			doVersionDBUpdates();
			
		}
		
		public static function newGUID():String
		{
			return UIDUtil.createUID();	
		}




		private function doVersionDBUpdates():void
		{
			/**
			 * Automatically updates DB tables and migrates data as necessary.
			 * 
			 * This will grow with releases.
			 * 
			 * The Version table is created if not exists in createDatabase() 
			 */
			
			var lastVersion:String;
			
				
			// 1) check the DB version - get the most recent installed version
			var sql:SQLStatement = new SQLStatement();
			sql.text = "SELECT explicitVersion FROM version ORDER BY dateCreated desc LIMIT 1 ";
			
			DB.doSQL( sql );
			
			var res:SQLResult = sql.getResult();
			
			if(null!=res.data)
			{
				lastVersion = res.data[0].explicitVersion; 
			}
			else
			{
				sql.clearParameters();
				sql.text = "INSERT INTO version (explicitVersion, dateCreated) VALUES(:v, strftime('%s','now') ) ";
				sql.parameters[":v"] = currentVersion;				
				DB.doSQL( sql );
			}
				
			// we can just add the column
			var hasCol:Boolean=false;
			var row:SQLColumnSchema;
			var cols:Array; var i:int; var j:int;
			
			//ah_20090825-00 added globalsetting and usersetting tables; nothing to do
			sql.clearParameters();
			sql.text = "SELECT * FROM globalsetting ";
			DB.doSQL( sql );
			if(null==sql.getResult().data)
			{
				sql.clearParameters();
				sql.text = "INSERT INTO globalsetting (autoSignIn) VALUES(0)";
				DB.doSQL( sql );
			}
						
			
			
			//finally, add the current version to the db
			sql.clearParameters();
			sql.text = "UPDATE version SET explicitVersion=:v, dateCreated = strftime('%s','now') ";
			sql.parameters[":v"] = currentVersion;			
			DB.doSQL( sql ); 
			
		}

		
		
		
		private function createDatabase() : void
		{
			var sql:SQLStatement = new SQLStatement();			
			
			
			//Version table
			sql.text = "CREATE TABLE IF NOT EXISTS	version	(" + 
					"	versionID	INTEGER	PRIMARY KEY AUTOINCREMENT " + 
					",	explicitVersion	TEXT " + 
					",	dateCreated	INTEGER	)";
			DB.doSQL( sql );
						

			//Global settings
			sql.text = "CREATE TABLE IF NOT EXISTS	globalsetting	(" + 
				"	settingID	INTEGER	PRIMARY KEY AUTOINCREMENT " + 
				",	autoSignIn	INTEGER " + 
				",	lastUserGUID	TEXT	)";
			DB.doSQL( sql );

			
			sql.text = "CREATE TABLE IF NOT EXISTS	attachment	(" + 
				"	attachmentGUID	TEXT	UNIQUE " + 
				",	taskGUID	TEXT " + 
				",	userGUID	TEXT " + 
				",	sourcepath	TEXT " + 
				",	storepath	TEXT " + 
				",	title	TEXT " + 
				",	filetype	TEXT " + 
				",	sha1digest	TEXT " + 
				",	isManaged	INTEGER " + 
				",	sourceType	INTEGER " + 
				",	haveData	INTEGER " + 
				",	dateCreated	INTEGER " + 
				",	dateModified	INTEGER	)";
			DB.doSQL(sql);
			
			
			sql.text = "CREATE TABLE IF NOT EXISTS	mailmessage	(" + 
					"	mailMessageGUID	TEXT	UNIQUE " + 
					",	taskGUID	TEXT " + 
					",	userGUID	TEXT " + 
					",	messageID	TEXT " + 
					",	profileGUID	TEXT " + 
					",	lastMailboxName	TEXT " + 
					",	subject	TEXT " + 
					",	fromAddress	TEXT " + 
					",	toAddress	TEXT " + 
					",	replyToAddress	TEXT " + 
					",	ccAddress	TEXT " + 
					",	bccAddress	TEXT " + 
					",	messageDate	TEXT " + 
					",	mimeVersion	TEXT " + 
					",	contentType	TEXT " + 
					",	bodyStructure	TEXT " + 
					",	dateCreated	INTEGER " + 
					",	dateModified	INTEGER	)";
			DB.doSQL(sql);
			
		
			
		}
	}
}