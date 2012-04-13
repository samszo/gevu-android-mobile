package 
{
	import flash.events.EventDispatcher;
	
	import mx.collections.IList;
	
	public class DiskGroup extends EventDispatcher{
		//[Embed("diskgroup.gif")]
		public static var RedundancyIcon:Class;
		
		[Bindable]public var enable:Boolean=true;
		
		private var _redundancyType:String;
		private var _id:int=1;
		
		//item type is VolumeDiskItem
		private var _diskList:IList;
		
		public function DiskGroup($redunancyType:String, $id:int) {
			this._redundancyType = $redunancyType;
			this._id = $id;
		}
		
		public function get redundancyType():String{
			return this._redundancyType;
		}
		
		[Bindable]
		public function get label():String {
			return this._redundancyType;
		}
		
		public function set label(v:String):void {
			this._redundancyType = v;
		}
		
		public function get icon():Class{
			return RedundancyIcon;
		}
		
		//item type is Disk
		public function get children():IList {
			return this._diskList;
		}
		
		//item type is Disk
		public function set children(v:IList):void{
			this._diskList = v;
		}
		
		public function get selectable():Boolean{
			return enable;
		}
		
		public function get getID():int{
			return this._id;
		}
		private var _treeid:String = null;
		public function get treeid():String {
			if ( ! _treeid ) {
				_treeid = "redundancy" + this._id;
			}
			return _treeid;
		}
	}
}