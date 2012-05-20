package com.sparkTree 
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.getQualifiedClassName;
	import mx.collections.IList;
	import mx.collections.XMLListAdapter;
	import mx.collections.XMLListCollection;

	//import mx.collections.XMLListCollection;
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	import mx.utils.ArrayUtil;

	public class TreeItemList implements IList
	{
		//should be XMLCollection or ArrayCollection
		private var _source:IList;
		
		private var _collection: TreeItemCollection;
		private var _eventDispatcher:EventDispatcher;
		public var owner:TreeItem;
		
		public function TreeItemList($collection: TreeItemCollection, $owner:TreeItem, $source:IList) 
		{
			super();
			this._eventDispatcher = new EventDispatcher(this);
			this.owner = $owner;
			this._collection = $collection;

			//因为 TreeItemList 构造函数可能由TreeDataProvider调用, 
			//为了保证TreeItemList XML List为 XMLList1, 所以做了特殊处理
			
			if ($source is XMLListCollection) {
				this._source = new XMLList1(  XMLListCollection($source).source );
			} else if ($source is XMLListAdapter) {
				this._source = new XMLList1(  XMLListAdapter($source).source );
			} else {
				this._source = $source;
			}
			
//trace("TreeItemList, add CollectionEvent for source, it's class=" + getQualifiedClassName( _source) );
//trace("TreeItemList, add CollectionEvent for source, source=" + _source );

			this._source.addEventListener(CollectionEvent.COLLECTION_CHANGE, sourceChangeHandle, false, int.MAX_VALUE);
		}

		//item is TreeItem
		private var _items:Array = new Array();
		private var sourceIsDirty:Boolean = true;
		
		private function safeRemoveEventListener():void {
			if ( this._source.hasEventListener(CollectionEvent.COLLECTION_CHANGE)) {
				//trace("remove listener");
				this._source.removeEventListener(CollectionEvent.COLLECTION_CHANGE, sourceChangeHandle, false);
			}
		}
		
		private function sourceChangeHandle(event:CollectionEvent):void {
trace("TreeItemList sourceChangeHandle, event.kind=" + event.kind);
//trace("this.source.items[0].@label="+this._source.getItemAt(0).@label);
			event.stopImmediatePropagation();
			event.preventDefault();
/*			
			if (event.kind == CollectionEventKind.UPDATE && event.location == -1 && event.oldLocation == -1 &&
				event.items && event.items[0] && 
				event.items[0] is PropertyChangeEvent &&
				(event.items[0].kind ==  PropertyChangeEventKind.UPDATE ) &&
				!event.items[0].property && 
				!event.items[0].newValue && 
				!event.items[0].oldValue) {
trace("it is a descendant's property change, ignore!");					
				return;
				
			}
*/
			if (event.items && event.items.length>0) {
				_collection.convertEventItems(event.items, owner, safeRemoveEventListener);
			}

			if ( ! this._source.hasEventListener(CollectionEvent.COLLECTION_CHANGE) && (!sourceIsDirty) ) {
				//trace("add listener");
				this._source.addEventListener(CollectionEvent.COLLECTION_CHANGE, sourceChangeHandle, false, int.MAX_VALUE);
			}
			
			sourceIsDirty = true;
			this.dispatchEvent(event);
		}

		private function getItems():Array {
			if (sourceIsDirty) {
//trace("TreeItemList refresh items");
				_items = null;
				var srcAry:Array = _source.toArray();

				if (srcAry) {
					_items = _collection.convertNodesToItems(srcAry, owner, safeRemoveEventListener);
					
				}

				sourceIsDirty = false;

				if ( ! this._source.hasEventListener(CollectionEvent.COLLECTION_CHANGE) ) {
					//trace("add listener");
					this._source.addEventListener(CollectionEvent.COLLECTION_CHANGE, sourceChangeHandle, false, int.MAX_VALUE);
				}
			}
			
			return _items;
		}

		public function get length () : int {
			return getItems().length;
		}
		
		//item is TreeItem
		public function addItem (item:Object) : void {
trace("TreeItemList addItem");						
			if ( ! item ) return;
			
			if ( ! (item is TreeItem) ){
				throw new Error("MyDataProvider's item should be TreeItem");
			}
			
			_source.addItem( (item as TreeItem).source );
		}

		public function addItemAt (item:Object, index:int) : void {
trace("TreeItemList addItemAt");
			if ( ! item ) return;
			
			if ( ! (item is TreeItem) ){
				throw new Error("TreeItemList's item should be TreeItem");
			}
			
			_source.addItemAt( (item as TreeItem).source, index );
		}

		//return item is a TreeItem
		public function getItemAt (index:int, prefetch:int = 0) : Object {
			return getItems()[index];
		}
		
		//item is TreeItem
		public function getItemIndex (item:Object) : int {
			if ( ! item ) {
				return -1;
			} else {
				if ( ! (item is TreeItem) ){
					throw new Error("TreeItemList's element should be TreeItem");
				}
				
				return getItems().indexOf(item);
/*				
				var tmp:Array = getItems();
				
				for (var i:int = 0; i < tmp.length; i++ ) {
					if (tmp[i] == item) {
						return i;
					}
				}
				return -1;
*/
				//return _source.getItemIndex( (item as TreeItem).source );
			}
		}

		public function itemUpdated (item:Object, property:Object = null, oldValue:Object = null, newValue:Object = null) : void {
//trace("TreeItemList itemUpdated");	
			if ( ! item ) {
				_source.itemUpdated(item,property,oldValue,newValue);
			} else {
				if ( ! (item is TreeItem) ){
					throw new Error("TreeItemList's element should be TreeItem");
				}
				_source.itemUpdated( (item as TreeItem).source ,property,oldValue,newValue);
			}
		}

		//该函数只是将source上的 eventListener删除, 并不对所封装的数据进行删除
		//如果同时也想做清除动作(就是一个reset), 请调用 removeAll()
		public function detach(): void {
trace("TreeItemList detach");			
			this.safeRemoveEventListener();
			
			if(getItems() && getItems().length>0){
				for each( var tmp:TreeItem in getItems()) {
					if (tmp && tmp.childrens) {
						TreeItemList(tmp.childrens).detach();
					}
					_collection.removeItem(tmp);
				}
				
				_items = null;
			}

			_source = null;
			sourceIsDirty = true;
		}
		
		public function removeAll () : void {
trace("TreeItemList removeAll");
			_source.removeEventListener(CollectionEvent.COLLECTION_CHANGE, sourceChangeHandle);
			_source.removeAll();
			
			if(_items){
				for each( var tmp:TreeItem in _items) {
					if (tmp && tmp.childrens && tmp.childrens.length>0) {
						tmp.childrens.removeAll();
					}
					_collection.removeItem(tmp);
				}
			}
			//_items.
			_items.length = 0;
			sourceIsDirty = true;
		}

		//it's not IList API
		public function removeItem(item:TreeItem):void {
			if (item) {
				var tmp:int = _source.getItemIndex(item.source);
				if (tmp >= 0) {
					removeItemAt(tmp);
				}
			}
		}
		
		public function removeItemAt (index:int) : Object {
//trace("TreeItemList removeItemAt");
			var o:Object = _source.removeItemAt(index);
			if ( ! o ) return null;
			else {
				return _collection.removeNode(o);
			}
		}
		
		public function setItemAt (item:Object, index:int) : Object {
//trace("TreeItemList setItemAt");
			if (! item || index < 0) return item;
			return _collection.find(_source.setItemAt( (item as TreeItem).source, index));
		}

		public function toArray () : Array {
//trace("TreeItemList toArray");				
/*	
			var oa:Array = this._source.toArray();
			if ( ! oa ) return oa;
			var result:Array = [];
			for each(var a:* in oa) {
				result.push(_collection.wrapper(a));
			}
			return result;
*/
			return this.getItems();
		}
		
		public function get level():int {
			if (owner) return owner.indentLevel + 1;
			else return 0;
		}
		
		public function addEventListener (type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false) : void {
			this._eventDispatcher.addEventListener(type,listener,useCapture,priority,useWeakReference);
		}

		public function dispatchEvent (event:Event) : Boolean {	
			return _eventDispatcher.dispatchEvent(event);
		}

		public function hasEventListener (type:String) : Boolean {
			return this._eventDispatcher.hasEventListener(type);
		}

		public function removeEventListener (type:String, listener:Function, useCapture:Boolean = false) : void {
			this._eventDispatcher.removeEventListener(type, listener, useCapture);
		}

		public function willTrigger (type:String) : Boolean {
			return this._eventDispatcher.willTrigger(type);
		}
		
	}

}