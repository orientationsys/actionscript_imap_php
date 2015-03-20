package com.robotblimp.helium.services.crypt
{
	import com.adobe.crypto.SHA1;
	
	public class Digest extends SHA1
	{
		public function Digest()
		{
			super()
		}

		public function fingerprint(obj:Object):String
		{
			if(obj is String){
				return hash(String(obj));
			}
			else{
				var rawMessage:ByteArray = new ByteArray();
				rawMessage.writeUTFBytes(obj);
				return hashBytes( rawMessage );
			}
		}
	}
}