package com.robotblimp.helium.services.log
{
	import com.robotblimp.helium.services.db.*;
	
	import flash.data.SQLStatement;
	
	import mx.core.FlexGlobals;
	
	public class Logger
	{
		private var DB:Database;
		private var sql:SQLStatement;
		
		public function Logger()
		{
			DB = FlexGlobals.topLevelApplication.Sys.DB;
			
		}
		
		public function log(msg:String):void
		{
			sql = new SQLStatement();
			sql.text = "INSERT INTO logging (message, dateCreated) " + 
					"VALUES(:message, strftime('%s','now') )";
			sql.parameters[":message"] = msg;
			DB.doSQL( sql );
		}

	}
}