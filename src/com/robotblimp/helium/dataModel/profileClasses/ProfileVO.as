package com.robotblimp.helium.dataModel.profileClasses
{
	import com.robotblimp.helium.services.db.Database;
	
	import flash.data.SQLStatement;

	public class ProfileVO
	{
		public var profileGUID:String;
		public var userGUID:String;
		public var profileType:int;
		public var profileName:String;
		public var enabled:Boolean;
		public var displayIcon:Class;
		
		public function ProfileVO()
		{
		}

		public function update(DB:Database):void
		{
			var sql:SQLStatement = new SQLStatement();
			sql.text = "UPDATE externalprofile " +
				"SET profileType=:ProfileType, profileName=:ProfileName, enabled=:Enabled " +
				"WHERE profileGUID=:ProfileGUID AND userGUID=:UserGUID ";
			sql.parameters[":ProfileType"] = profileType;
			sql.parameters[":ProfileName"] = profileName;
			sql.parameters[":Enabled"] = enabled;
			sql.parameters[":ProfileGUID"] = profileGUID;
			sql.parameters[":UserGUID"] = userGUID;
			DB.doSQL(sql);
		}
	}
}