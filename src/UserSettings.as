package
{
	import com.robotblimp.helium.dataModel.profileClasses.ExchangeProfileVO;

	public class UserSettings
	{
		public var profile:ExchangeProfileVO;;
		static public const Profile_Exchange:int=0;
		static public const Profile_GMail:int=1;
		static public const Profile_IMAP:int=2;
		static public const Profile_MobileMe:int=3;
		
		public function UserSettings(userGUID:String)
		{
		}

		public function getExchangeProfile(profileGUID:String):ExchangeProfileVO
		{
			return profile;	
		}
		
		public function get ExchangeProfiles():Array
		{
			return [ profile ];
		}		
	}
}