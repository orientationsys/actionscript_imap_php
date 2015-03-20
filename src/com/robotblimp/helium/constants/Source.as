package com.robotblimp.helium.constants
{
	public final class Source
	{
		public static const NATIVE:uint	= 1;
		public static const EXCHANGE:uint = 2;
		public static const IMAP:uint		= 3;
		public static const EVERNOTE:uint	= 4;
		public static const TWITTER:uint	= 5;
		public static const FILESYSTEM:uint = 6;
		
		public static const ITERABLE_SOURCES:Array = 
			[NATIVE, EXCHANGE, IMAP, EVERNOTE, TWITTER];
		public static const ITERABLE_SOURCETITLES:Array = 
			['Helium','Exchange','IMAP','Evernote','Twitter'];
		public static const SOURCETITLES:Object = 
			{1:'Helium',2:'Exchange',3:'IMAP',4:'Evernote',5:'Twitter'};
	}
}