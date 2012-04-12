package {
	import flash.events.EventDispatcher;
	
	import mx.collections.IList;

	public class Disk extends EventDispatcher{
		[Embed("storage.png")]
		public static var DiskIcon:Class;
		
		public var id:String;
		public function Disk($diskId:String) {
			this.id = $diskId;
		}
		
		[Bindable]
		public function get label():String {
			return id;
		}
		
		public function set label(v:String):void {
			//do nothing
		}
		public function get icon():Class{
			return DiskIcon;
		}
		public function get children():IList {
			return null;
		}

		public function get selectable():Boolean{
			//return true;
			return false;
		}
		
		private var _treeid:String = null;
		public function get treeid():String {
			if ( ! _treeid ) {
				_treeid = "disk" + this.id;
			}
			return _treeid;
		}
	}
}