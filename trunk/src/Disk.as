package {
	import flash.events.EventDispatcher;
	
	import mx.collections.IList;

	public class Disk extends EventDispatcher{
		//[Embed("storage.png")]
		public static var DiskIcon:Class;
		
		public var id:String;
		private var _newId:int;
		private var _treeid:int;
		
		public function Disk($label:String,$id:int) {
			this.id = $label;
			this._newId=$id;
		}
		
		[Bindable]
		
		public function get getID():int{
			return this._newId;
		}
		
		public function get label():String {
			return this.id;
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
		
		
		public function get treeid():int {
			_treeid = this._newId;
			return _treeid;
		}
	}
}