package com.robotblimp.helium.constants
{
	public class box_constants
	{
		//constants for task.organizeBox:Integer
		public static const BOX_PROJECTONLY:uint = 0;		
		public static const BOX_NOW:uint = 2;
		public static const BOX_SCHEDULED:uint = 3;
		public static const BOX_WAITINGON:uint = 4;
		public static const BOX_SOMEDAY:uint = 5;
		public static const BOX_DELEGATED:uint = 6;
		//public static const BOX_SHARED:uint = 7;
		public static const BOX_ALLPROJECTS:uint = 10;
		public static const BOX_ARCHIVE:uint = 100;
		public static const BOX_QUEUE:uint = 200;
		public static const BOX_TRASH:uint = 500;
		
		public static const ITERABLE_BOXES:Array = 
			[BOX_PROJECTONLY, BOX_NOW, BOX_SCHEDULED, BOX_WAITINGON, BOX_SOMEDAY, BOX_DELEGATED, BOX_QUEUE];
		public static const ITERABLE_BOXTITLES:Array = 
			['Project Only', 'Now', 'Scheduled', 'Waiting On', 'Someday', 'Delegated', 'Queue'];
		
		public static const ALL_BOXES:Array = 
			[BOX_PROJECTONLY, BOX_NOW, BOX_SCHEDULED, BOX_WAITINGON, BOX_SOMEDAY, BOX_DELEGATED
			, BOX_ARCHIVE, BOX_QUEUE, BOX_TRASH];
		
		public static const ALL_BOXTITLES:Array = 
			['Project Only', 'Now', 'Scheduled', 'Waiting On', 'Someday', 'Delegated'
			, 'Archive', 'Queue', 'Trash'];
			
		public static function BOX_ID_TITLE(boxID:uint):String
		{ 
			switch(boxID)
			{
				case BOX_PROJECTONLY:
					return 'Project Only';
					break;
				case BOX_NOW:
					return 'Now';
					break;
				case BOX_SCHEDULED:
					return 'Scheduled';
					break;
				case BOX_WAITINGON:
					return 'Waiting On';
					break;
				case BOX_SOMEDAY:
					return 'Someday';
					break;
				case BOX_DELEGATED:
					return 'Delegated';
					break;
				case BOX_ARCHIVE:
					return 'Archive';
					break;
				case BOX_QUEUE:
					return 'Queue';
					break;
				case BOX_TRASH:
					return 'Trash';
					break;
				default:
					return '';
			}	
		}
	}
}