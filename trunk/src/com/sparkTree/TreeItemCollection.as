package com.sparkTree 
{
	import flash.utils.getQualifiedClassName;
	import mx.events.PropertyChangeEvent;
	
	public class TreeItemCollection 
	{
		private var _arr:Object = new Object();

		public function TreeItemCollection() {
		}
		
		private function push($itemId:*, $item:TreeItem):void {
//trace("push "+$item.getInelID()+", item="+$item.source.@label);			
			_arr[$itemId] = $item;
		}
		
		private function getItemByID($itemId:*):TreeItem {
			var a:TreeItem = _arr[$itemId];
//trace("get "+id+", return "+a);			
			return a;
		}
		
		public function find($node:Object): TreeItem {
			if ( ! $node ) return null;
			
			var _itemId:* = itemIdentify($node);
			if ( ! _itemId ) {
				throw new Error("can not get valid identify for node: "+$node);
			}
			return getItemByID(_itemId);
		}
		
		public function removeAll():void {
			_arr = null;
			_arr = new Object();
		}
		
		public function removeNode($node:Object): TreeItem {
			if ($node) {
				var tmp:TreeItem = find($node);
				removeItem(tmp);
				return tmp;
			}
			return null;
		}

		public function removeItem($item:TreeItem): void {
			if ($item) {
trace("TreeitemCollection.removeItem");						
				delete _arr[$item.getItemId()];
			}
		}
		
		private var sparkTreeAutoCreateID:int = 1;

		public function convertEventItems(eventItems:Array, $owner:TreeItem, f:Function = null):void {
			if ( ! eventItems ) return;

			for (var i:int = 0; i < eventItems.length; i++ ) {
				var node:Object = eventItems[i];
				if (node is PropertyChangeEvent) {
					if ( ! node.source.hasOwnProperty(itemIdentifyField) && allowAutoIdentify ) {
						if( f != null ){
							f();
						}
						node.source[itemIdentifyField] = "__treeID_" + sparkTreeAutoCreateID++;
					}
					eventItems[i].source = wrapper(node.source, $owner);
				} else {
					if ( ! node.hasOwnProperty(itemIdentifyField) && allowAutoIdentify ) {
						if( f != null ){
							f();
						}
						node[itemIdentifyField] = "__treeID_" + sparkTreeAutoCreateID++;
					}
					eventItems[i] = wrapper(node, $owner);
				}
			}
		}
		
		public function convertNodesToItems($nodes:Array, $owner:TreeItem, f:Function = null):Array {
			if ( ! $nodes ) return null;

			var ret:Array = [];
			
			for (var i:int = 0; i < $nodes.length; i++ ) {
				var node:Object = $nodes[i];
				
				if ( ! node.hasOwnProperty(itemIdentifyField) && allowAutoIdentify ) {
					if( f != null ){
						f();
					}
					node[itemIdentifyField] = "__treeID_" + sparkTreeAutoCreateID++;
				}
				ret.push(wrapper(node, $owner));
			
			}
			
			return ret;
		}
		
		private function wrapper($node:Object,$owner:TreeItem) :TreeItem {
			if ( $node == null ) return null;
			else {
//trace(f+" >>>>>>>>>>>>>>>>>>>>");	
//trace(f+" $p.@label="+$p.@label);				

				var $itemId:* = itemIdentify($node);

				if ( ! $itemId ) {
					throw new Error("Can convert node ["+$node+"] to TreeItem");
				}
				
//trace(f+" $p.@sparkTreeInelID="+a);
				var existItem:TreeItem = getItemByID($itemId);
				if ( existItem ) {
//trace(f+" found $p.@sparkTreeInelID="+existItem.getInelID());
					return existItem;
				} else {
					var newItem1:TreeItem = new TreeItem(this,$owner,$node, $itemId);
					push($itemId,newItem1);
//trace(f+" push not "+newItem1.getInelID()+", item="+newItem1.source.@label);
					return newItem1;
				}
				
			}
		}


//======================= node's identify =======================
		public var allowAutoIdentify:Boolean = false;
		
		public function itemIdentify(item:Object):* {
			return itemToIdentify(item, itemIdentifyField, itemIdentifyFunction);
		}

		private var _identifyField:String = "@id";
		private var _identifyFunc:Function;
		
		public function get itemIdentifyField():String {
			return this._identifyField;
		}
		
		public function set itemIdentifyField(field:String):void {
			this._identifyField = field;
		}
		
		public function get itemIdentifyFunction():Function {
			return this._identifyFunc;
		}
		
		public function set itemIdentifyFunction(func:Function):void {
			this._identifyFunc = func;
		}

		
		//return should be int or string
		public static function itemToIdentify(item:Object, idField:String = null, idFunc:Function = null):* {
			if ( ! item ) return undefined;
			
			if (idFunc != null){
				var r:* = idFunc(item);
				if ( r is int) {
					return int(r);
				}

				if ( r is String) {
					return String(r);
				}
				return undefined;
//trace("itemIdentifyFunction should return String or int");
			}

			// early check for Strings
			if (item is String)
				return String(item);
			
			if (item is int)
				return int(item);

			if (item is XML) {
				try {
					if (item[idField].length() != 0)
						item = item[idField].toString();
					//by popular demand, this is a default XML labelField
					//else if (item.id.length() != 0)
					//  item = item.@id;
				} catch(e:Error) {
				}
			} else {// regarded as Object, or custom Object
				try{
					if (item[idField] != null)
						item = item[idField];
				} catch(e:Error) {
				}
			}

			// late check for strings if item[labelField] was valid
			if (item is String)
				return String(item);
			if (item is int)
				return int(item);

			throw new Error("item["+idField +"]'s should be String or int");
			//return undefined;
//trace("item["+item +"]'s identifyField value should be String or int");
		}
		
	}

}