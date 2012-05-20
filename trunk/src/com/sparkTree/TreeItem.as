package com.sparkTree
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.utils.getQualifiedClassName;
    
    import mx.collections.ArrayCollection;
    import mx.collections.ArrayList;
    import mx.collections.IList;
    import mx.collections.XMLListCollection;
    
    public class TreeItem extends EventDispatcher
    {
        private var _expanded:Boolean;
        private var _parent:TreeItem;
		
        private var _children:TreeItemList;
		private var _source:Object;
		
		private var _itemId:*;
		
		private var _parsedChildsFromSource:Boolean = false;
		private var _collection:TreeItemCollection;

        public function TreeItem($collection:TreeItemCollection,$parent:TreeItem, node:Object, $nodeId:*)
        {
			this._collection = $collection;
			this._source = node;
			this._itemId = $nodeId;
			this._parent = $parent;
			this._children = null;
        }

		
		
		public function getItemId():* {
			return this._itemId;
		}
		
		public function get collection():TreeItemCollection{
			return this._collection;
		}
		
		public function get source():Object {
			return this._source;
		}

		public function getIcon(iconOpenField:String):Class {
			if ( ! _source ) return null;
			return this._source.hasOwnProperty(iconOpenField) ? this._source[iconOpenField] : null;
		}

		public function hasChildren():Boolean {
			//use childrens, not _children
			if (childrens && childrens.length > 0) return true;
			return false;
		}

		public function isBranch():Boolean {
			return nodeIsBranch(source);
		}

		public function get enableSelection():Boolean {
			return nodeEnableSelection(source);
		}
		
		private var _hasFetchedChild:Boolean = false;
		
		public function get hasFetchedChild():Boolean {
			if ( hasChildren() ) return true;
			return _hasFetchedChild;
		}
		
		public function set hasFetchedChild(f:Boolean):void {
			this._hasFetchedChild = f;
		}
		
        public function setParent(item:TreeItem):void
        {
            if(item == this)
                throw new Error("We cannot be our own parent");
            
            if (_parent) {
				var tmpIndex:int = _parent.branch.getItemIndex(item);
				_parent.branch.removeItemAt(tmpIndex);
			}
            
            _parent = item;
        }

        public function get indentLevel():int
        {
            if(parent)
                return parent.indentLevel + 1;
            
            //return 0;
			//has a default root 
			return -1;
        }

        [Bindable]
        public function get expanded():Boolean { return _expanded; }
        public function set expanded(value:Boolean):void 
        { 
            if(value == _expanded)
                return;
            
            _expanded = value;
        }
        
        public function get parent():TreeItem { return _parent; }

		public function get branch():TreeItemList {
			return _parent.childrens as TreeItemList;
		}

        //return IList's item is TreeItem
        public function get childrens():IList {
			if(this._parsedChildsFromSource){
				return _children; 
			} else {

				var list:IList = getNodeChildren(_source);
//trace("getNodeChildren return class="+ getQualifiedClassName(list));
				if(list){
					_children = new TreeItemList(_collection, this, list);
					_parsedChildsFromSource = true;
				} else {
					_children = null; 
				}
				
				return _children;
			}
		}
		
		//value:IList item is TreeItem
        public function set childrens(value:IList):void
        {
//trace("****************  TreeItem set childrens!!!!!!!!!");	
//trace("set childrens, value.class="+getQualifiedClassName(value));
			if (value == null) {
				this._children = null;
			} else if ( value is TreeItemList ) {
				this._children = value as TreeItemList;
			} else if (value is IList) {
//trace("set childrens, value.class="+getQualifiedClassName(value));				
				this._children = new TreeItemList(_collection, this, IList(value));
			}
			_parsedChildsFromSource = true;
			_hasFetchedChild = true;
        }
		
		//================== some fucntion for origianl object ========

		private static function nodeEnableSelection(node:Object):Boolean {
			if (node == null)
				return false;
			
			var nes:Boolean = false;
			
			if (node is XML)
			{
				var flag:XMLList = node.@selectable;
				if (flag.length() == 1) {
					if (flag[0] == "true") nes = true;
				}
			} else if (node is Object) {
				try{
					if (node.selectable != undefined){
						nes = node.selectable;
					} else {
						nes = true;
					}
				} catch(e:Error) {
				}
			}
			return nes;
		}

		private static function nodeIsBranch(node:Object):Boolean
		{
			if (node == null)
				return false;

			var _isBranch:Boolean = false;

			if (node is XML)
			{
				var childList:XMLList = node.children();
				//accessing non-required e4x attributes is quirky
				//but we know we'll at least get an XMLList
				var branchFlag:XMLList = node.@isBranch;
				//check to see if a flag has been set
				if (branchFlag.length() == 1)
				{
					//check flag and return (this flag overrides termination status)
					if (branchFlag[0] == "true")
						_isBranch = true;
				}
				//since no flags, we'll check to see if there are children
				else if (childList.length() != 0)
				{
					_isBranch = true;
				}
			}
			else if (node is Object)
			{
				try
				{
					if (node.children != undefined)
					{
						_isBranch = true;
					}
				}
				catch(e:Error)
				{
				}
			}
			return _isBranch;
		}

		//return may be XMLListCollection, ArrayList, ArrayCollection, XMLListCollection
		public static function getNodeChildren(node:Object):IList
		{
/*			
			var len:int = 0;
			var a:Array;
			len = a.length;
			for each( var k:* in a) {
				
			}
			
			var b:IList;
			len = b.length;
			for each(var k1:* in b) {
				
			}
			
			var c:XMLList;
			len = c.length;
			for each(var k2:* in c) {
				
			}
*/			
			if (node == null)
				return null;
				
			//first get the children based on the type of node. 
			if (node is XML){
				var tmp1:* = node.*;
				if (tmp1 != undefined) {
					return new XMLList1(XMLList(tmp1));
				} else {
					return null;
				}
			} else if (node is Object){
				//we'll try the default children property
				var tmp2:* = undefined;
				try{
					tmp2 = node.children;
				}catch (e:Error) { }
				
				if (tmp2) {
					if (tmp2 is Array) {
						return new ArrayList(tmp2 as Array);
					} else if (tmp2 is ArrayCollection) {
						return ArrayCollection(tmp2);
					} else if (tmp2 is XML) {
						return new XMLList1(new XMLList(tmp2 as XML));
					} else if (tmp2 is XMLList) {
						return new XMLList1(XMLList(tmp2));
					} else if (tmp2 is XMLList1) {
						return XMLList1(tmp2);
					} else if ( tmp2 is XMLListCollection) {
						return XMLList1(XMLListCollection(tmp2).source);
					} else if ( tmp2 is Vector) {
						var v:Vector = tmp2 as Vector;
						var ar:Array = new Array();
						for each(var xx:* in v ) {
							ar[ar.length] = xx;
						}
						return new ArrayList(ar);
					} else if ( tmp2 is Object) {
						return new ArrayList([tmp2]);
					}
				} else {
					return null;
				}
			} else {
				throw new Error("node is not XML or Object??");
			}
			return null;
		}
				
    }
}