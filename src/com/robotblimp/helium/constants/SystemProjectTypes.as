package com.robotblimp.helium.constants
{
	public final class SystemProjectTypes
	{
		public static const TRASH:int		= 0;
		public static const NO_PROJECT:int 	= 1;
		public static const USER:int		= 2;
		public static const RECURRING:int	= 3;
		
		public static const SYSTEMONLY_PROJECTS:Array = 
			[TRASH, NO_PROJECT];
		public static const SYSTEMONLY_PROJECT_NAMES:Array = 
			['Trash', 'No Project'];
			
		public static const SYSTEM_PROJECT_NAMES:Array =
			['Trash', 'No Project', 'User', 'Recurring'];
	}
}