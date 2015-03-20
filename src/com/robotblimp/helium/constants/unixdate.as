package com.robotblimp.helium.constants
{
	public class unixdate
	{
		//make date calculations easier with constants!
		public static const msMinute:int 		= 1000 * 60;
		public static const msHour:int 			= 1000 * 60 * 60;
		public static const msDay:int 			= 1000 * 60 * 60 * 24;
		public static const days:Array 			= ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
		public static const shortDays:Array 	= ["Sun","Mon","Tues","Weds","Thurs","Fri","Sat"];
		public static const suffixes:Array 		= ['','st','nd','rd','th','th','th','th','th','th','th','th','th','th','th','th','th','th','th','th','th','st','nd','rd','th','th','th','th','th','th','th','st'];
		public static const months:Array 		= ["January","February","March","April","May","June","July","August","September","October","November","December"];
		public static const shortMonths:Array 	= ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
		
		public static function UTCtoLocal(unixdateSeconds:Number):Date
		{
			var LD:Date = new Date();
			var offsetMS:Number = LD.timezoneOffset * 60000;
			var localMS:Number = (unixdateSeconds *1000) + offsetMS;
			return new Date(localMS);
		} 
		
		public static function LocalToUTC(localTimeMilliseconds:Number):Number
		{
			var LD:Date = new Date();
			var offsetMS:Number = LD.timezoneOffset * 60000;
			var UTCms:Number = (localTimeMilliseconds + offsetMS);
			var UTCs:Number = UTCms / 1000;
			
			return Math.floor( UTCs );			
		}
		
		public static function daysFromToday(unixdateSecondsUTC:Number):int
		{
			var now:Date = new Date();
			var nowDay:Date = new Date(now.fullYear, now.month, now.date);
			
			var then:Date = UTCtoLocal(unixdateSecondsUTC);			
			var thenDay:Date = new Date(then.fullYear, then.month, then.date);
		
			return int((nowDay.time - thenDay.time)/msDay);
		}
	}
}