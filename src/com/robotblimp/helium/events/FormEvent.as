package com.robotblimp.helium.events
{
	import flash.events.Event;
	
	public class FormEvent extends Event
	{
		public var data:Object;
		
		public function FormEvent(type:String, data:Object, bubbles:Boolean=true, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.data = data;
		}
		
		override public function clone():Event {
            return new FormEvent(type, data, bubbles, cancelable);            
        }

	}
}