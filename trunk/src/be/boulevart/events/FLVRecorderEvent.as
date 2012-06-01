package be.boulevart.events
{
	import flash.events.Event;

	public class FLVRecorderEvent extends Event
	{
		public static var FLV_START_CREATION:String="flvCreationStarted"
		public static var FLV_CREATED:String="flvCreated"
		public static var PROGRESS:String="progress"
		private var _urlToFLV:String 
		private var _prgr:Number
		
		public function FLVRecorderEvent(type:String,url:String="",pr:Number=0, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this._urlToFLV=url;
			this.progress=pr;
		}
		
		public function get url():String{
			return _urlToFLV;
		} 
		
		public function get progress():Number{
			return _prgr;
		} 
		
		public function set progress(v:Number):void{
			_prgr=v;
		} 
	}
}