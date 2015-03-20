package com.robotblimp.helium.services.db
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.data.EncryptedLocalStore;
	
	public class Database
	{
		private var connection :SQLConnection;
		private var dbFile :File;
		private var _async:Boolean = false;
		
		public function Database(DBFile:File) : void
		{
			_async = async;	
			// Reference a file for your database
			dbFile = DBFile;// File.applicationStorageDirectory.resolvePath("EthnoCorder.db");
			
			//if the dbFile doesn't exist, we are creating a new one
			//	so lets clear the encrypted cache as well
			//	not perfect, but better than nothing
			if(!dbFile.exists)
			{
				//destroy the encrypted store to prevent DB manipulation attacks
				EncryptedLocalStore.reset();				
			}
			
			// and connect to it
			connection = new SQLConnection();
			connection.addEventListener(SQLEvent.OPEN, onDatabaseOpen);
			connection.addEventListener(SQLErrorEvent.ERROR, onDBOpenError);
			if(async){
				connection.openAsync(dbFile);
			}
			else{
				connection.open(dbFile);	
			}
		}
		public function disconnect():void
		{
			connection.close();			
		}
		
		public function get async():Boolean{
			return _async;
		}
		
		public function doSQL( sql:SQLStatement, asyncResultHandler:Function=null ) :void
		{
			sql.sqlConnection = connection;
			if(_async){
				sql.addEventListener(SQLEvent.RESULT,asyncResultHandler);
			}
			sql.execute();
		}
				
		public function getTableColumns(tableName:String):Array
		{
			connection.loadSchema(SQLTableSchema,tableName);
			return connection.getSchemaResult().tables[0].columns;
		}
		private function onDatabaseOpen( event:SQLEvent ) : void
		{
			trace("opened DB");
		}
				
		
		private function onDBOpenError( event:SQLEvent ) : void
		{
			trace("Failed to open DB");
		}
		
		
		private function onSQLError( event:SQLEvent ) : void
		{
			trace("SQL error: " + event.toString() );
		}
		
	}
}
