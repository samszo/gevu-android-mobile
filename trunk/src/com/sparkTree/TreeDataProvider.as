/* Copyright (c) 2010 Maxim Kachurovskiy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE. */

package com.sparkTree
{
import flash.events.EventDispatcher;
//import flash.utils.Dictionary;
import flash.utils.getQualifiedClassName;
import mx.collections.ListCollectionView;

import mx.collections.ICollectionView;
import mx.collections.IList;
import mx.collections.IViewCursor;
import mx.collections.ISort;
import mx.events.CollectionEvent;
import mx.events.CollectionEventKind;
import mx.events.PropertyChangeEvent;
import mx.events.PropertyChangeEventKind;

[Event(name="itemClose", type="TreeEvent")]
[Event(name="itemOpen", type="TreeEvent")]
[Event(name="itemOpening", type="TreeEvent")]

public class TreeDataProvider extends EventDispatcher implements IList, ICollectionView
{
	public var allowIncorrectIndexes:Boolean = false;
	
	private var levelOfLastRemovedItem:int = -1;
	private var _length:int = 0;

	//private var _dataProvider:TreeItemList;
	private var _root:TreeItem;

	private var _treeItemsManager:TreeItemCollection;

	/**
	 * Cache contains currently visible items in the correct order. Cache can
	 * have smaller length - it means it does not surely contains all items.
	 */
	private var cache:Vector.<Object>;
	

	private function branchLevel($branch:IList):int {
		return ($branch as TreeItemList).level;
	}

	private function openedBranchesToParentObjects($branch:Object):TreeItem {
		if ($branch) {
			if( ($branch as TreeItemList).owner && ($branch as TreeItemList).owner.expanded){
				return ($branch as TreeItemList).owner;
			}
		}
		return null;
	}

	private function parentObjectsToOpenedBranches($parent:Object):IList {
//trace("$parent.class="+getQualifiedClassName($parent));
		if ($parent) {
			if(($parent as TreeItem).expanded){
				return ($parent as TreeItem).childrens;
			} else {
				return null;
			}
		}
		return null;
	}
	
	//DP = data provider
	private var _originalDP:IList = null;
	public function TreeDataProvider($treeItemsManager:TreeItemCollection, $originalDP:IList)
	{
		if (_originalDP === $originalDP) {
trace("TreeDataProvider contructor: _originalDP === $originalDP");			
			return;
		}
		
		//if (_originalDP) {
		//	_originalDP.removeEventListener(CollectionEvent.COLLECTION_CHANGE, originalDPResetListener);
		//}
		
		_originalDP = $originalDP;
		
		if( _root && _root.childrens){//old 
			TreeItemList(_root.childrens).detach();
			_root = null;
		}

		_treeItemsManager = $treeItemsManager;
		if (_originalDP is TreeItemList) {
			_root = new TreeItem(_treeItemsManager, null, null, undefined);
			
			_root.childrens = _originalDP;
		} else {
			_root = new TreeItem(_treeItemsManager, null, null, undefined);
			//_originalDP.addEventListener(CollectionEvent.COLLECTION_CHANGE, originalDPResetListener);
			_root.childrens = new TreeItemList(_treeItemsManager, _root, _originalDP);
		}
		
		resetDataStructures();
	}

	//does not support REFRESH
	public function refresh():Boolean {
		/*
		resetCache();
		refreshLength();
		dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE, false,
			false, CollectionEventKind.REFRESH));
		return true;
		*/
		return false;
	}

	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------
	private function resetDataStructures():void{
		resetCache();
		
		if (this._root)
			openBranch(this.dataProvider, null, false);
	}
	
	private function resetCache():void
	{
		cache = new Vector.<Object>();
		//levelsCache = new Dictionary();
	}
		
/*
	private function originalDPResetListener(event:CollectionEvent):void {
		if ( event.kind == CollectionEventKind.RESET ) {
trace("data provider reset");
			clear();
			dispatchEvent(event);
		}
	}
*/
	public function detach():void {
		if ( _root ) {
			if( _root.childrens ){
				TreeItemList(_root.childrens).detach();
			}
			_root = null;
		}
		this.cache = null;
		this._length = 0;
		this._originalDP = null;
		this._treeItemsManager = null;
	}
	
	public function reset1():void {
		if ( _root ) {
			if( _root.childrens ){
				TreeItemList(_root.childrens).detach();
			}
			_root.childrens = null;
		}
		
		_treeItemsManager.removeAll();
		_root.childrens = new TreeItemList(_treeItemsManager, _root, _originalDP);

		this._length = 0;
		resetDataStructures();
	}
	
	private function get dataProvider():TreeItemList {
		if( _root ){
			return _root.childrens as TreeItemList;
		}
		return null;
	}

	[Bindable("collectionChange")]
	public function get length():int{
		return _length;
	}

	//--------------------------------------------------------------------------
	//
	//  Implementation of IList: methods
	//
	//--------------------------------------------------------------------------
	
	public function addItem(item:Object):void
	{
		this.dataProvider.addItem(item);
	}
	
	public function addItemAt(item:Object, index:int):void
	{
		if (index == 0)
		{
			this.dataProvider.addItemAt(item, 0);
			return;
		}
		
		if (allowIncorrectIndexes && index > length)
			index = length;
		
		// this code usually executes when item is dropped into tree
		// choose correct place for drop, see 
		// https://github.com/kachurovskiy/Spark-Tree/issues/6
		var previousItem:TreeItem = getItemAt(index - 1) as TreeItem;
		var previousItemLevel:int = getItemLevel(previousItem);
		var nextItem:TreeItem = index < length ? getItemAt(index) as TreeItem : null;
		var nextItemLevel:int = nextItem ? getItemLevel(nextItem) : -1;
		var effectiveItem:TreeItem;
		var indexDelta:int;
		if (nextItemLevel != previousItemLevel && nextItem &&
			levelOfLastRemovedItem == previousItemLevel)
		{
			indexDelta = 0;
			effectiveItem = nextItem;
		}
		else
		{
			indexDelta = 1;
			effectiveItem = previousItem;
		}
			
		var parent:TreeItem = getItemParent(effectiveItem);
if( ! parent ) {
	throw new Error("Why parent is null??!!"); //already have _root TreeItem
}
		var branch:IList = parent.childrens;
		var localIndex:int = branch.getItemIndex(effectiveItem);
		branch.addItemAt(item, localIndex + indexDelta);
	}
	
	public function getItemAt(index:int, prefetch:int=0):Object
	{
		if (index < 0 || index >= _length)
			throw new Error("index " + index + " is out of bounds");

		if (index < cache.length)
			return cache[index];
		
		var branches:Vector.<IList> = new Vector.<IList>();
		var branchIndexes:Vector.<int> = new Vector.<int>();
		var branch:IList = this.dataProvider;
		var branchLength:int = branch.length;
		var branchIndex:int = 0;
		var currentItem:Object = branch.getItemAt(branchIndex);
		var cacheIndex:int = 0;
		while (currentItem)
		{
			cache[cacheIndex++] = currentItem;
			if (index == 0)
				return currentItem;
			
			if (parentObjectsToOpenedBranches(currentItem) &&
				IList(parentObjectsToOpenedBranches(currentItem)).length > 0)
			{
				branches.push(branch);
				branchIndexes.push(branchIndex);
				branch = parentObjectsToOpenedBranches(currentItem);
				branchIndex = 0;
				branchLength = branch.length;
				index--;
				currentItem = branch.getItemAt(branchIndex);
			}
			else if (branchIndex < branchLength - 1)
			{
				branchIndex++;
				index--;
				currentItem = branch.getItemAt(branchIndex);
			}
			else if (branches.length > 0)
			{
				do
				{
					branch = branches.pop();
					branchIndex = branchIndexes.pop() + 1;
					branchLength = branch.length;
				} while (branches.length > 0 && branchIndex >= branchLength)
				index--;
				currentItem = branch.getItemAt(branchIndex);
			}
			else
			{
				throw new Error("index " + index + " is out of bounds");
			}
		}
		throw new Error("index " + index + " is out of bounds");
		return null;
	}
	
	public function getItemIndex(item:Object):int
	{
		if (!item)
			return -1;
		
		var cacheIndex:int = cache.indexOf(item);
		if (cacheIndex >= 0)
			return cacheIndex;
		
		var index:int = 0;
		var branches:Vector.<IList> = new Vector.<IList>();
		var branchIndexes:Vector.<int> = new Vector.<int>();
		var branch:IList = this.dataProvider;
		var branchLength:int = branch.length;
		if (branchLength == 0)
			return -1;
		var branchIndex:int = 0;
		var currentItem:Object = branch.getItemAt(branchIndex);
		cacheIndex = 0;
		while (currentItem)
		{
			cache[cacheIndex++] = currentItem;
			if (currentItem == item)
				return index;
			
			if (parentObjectsToOpenedBranches(currentItem) &&
				IList(parentObjectsToOpenedBranches(currentItem)).length > 0)
			{
				branches.push(branch);
				branchIndexes.push(branchIndex);
				branch = parentObjectsToOpenedBranches(currentItem);
				branchIndex = 0;
				branchLength = branch.length;
				index++;
				currentItem = branch.getItemAt(branchIndex);
			}
			else if (branchIndex < branchLength - 1)
			{
				branchIndex++;
				index++;
				currentItem = branch.getItemAt(branchIndex);
			}
			else if (branches.length > 0)
			{
				do
				{
					branch = branches.pop();
					branchIndex = branchIndexes.pop() + 1;
					branchLength = branch.length;
				} while (branches.length > 0 && branchIndex >= branchLength)
				index++;
				if (branchIndex < branchLength)
					currentItem = branch.getItemAt(branchIndex);
				else
					return -1;
			}
			else
			{
				return -1;
			}
		}
		return -1;
	}
	
	public function itemUpdated(item:Object, property:Object = null, 
		oldValue:Object = null, newValue:Object = null):void
	{
		this.dataProvider.itemUpdated(item, property, oldValue, newValue);
	}
	
	public function removeAll():void {
trace("TreedataProvider.removeAll");		
		this.dataProvider.removeAll();
	}
	
	public function removeItemAt(index:int):Object {
		var item:TreeItem = getItemAt(index) as TreeItem;
		if (item) {
			if ( item.branch ) {
				levelOfLastRemovedItem = item.indentLevel;
				var tmpIndex:int = item.branch.getItemIndex(item);
				return item.branch.removeItemAt(tmpIndex);
			} else {
				var ai:int = this.dataProvider.getItemIndex(item);
				if (ai >= 0) {
					levelOfLastRemovedItem = 0;
					return this.dataProvider.removeItemAt(ai);
				}
			}
		}
		return null;
	}

	public function setItemAt(item:Object, index:int):Object
	{
		var currentItem:TreeItem = getItemAt(index) as TreeItem;
		var localIndex:int = currentItem.branch.getItemIndex(currentItem);
		return currentItem.branch.setItemAt(item, localIndex)
	}
	
	public function toArray():Array
	{
		var result:Array = [];
		var branches:Vector.<IList> = new Vector.<IList>();
		var branchIndexes:Vector.<int> = new Vector.<int>();
		var branch:IList = this.dataProvider;
		var branchLength:int = branch.length;
		var branchIndex:int = 0;
		var currentItem:Object = branch.getItemAt(branchIndex);
		while (true)
		{
			result.push(currentItem);
			
			if (parentObjectsToOpenedBranches(currentItem) &&
				IList(parentObjectsToOpenedBranches(currentItem)).length > 0)
			{
				branches.push(branch);
				branchIndexes.push(branchIndex);
				branch = parentObjectsToOpenedBranches(currentItem);
				branchIndex = 0;
				branchLength = branch.length;
				currentItem = branch.getItemAt(branchIndex);
			}
			else if (branchIndex < branchLength - 1)
			{
				branchIndex++;
				currentItem = branch.getItemAt(branchIndex);
			}
			else if (branches.length > 0)
			{
				do
				{
					branch = branches.pop();
					branchIndex = branchIndexes.pop() + 1;
					branchLength = branch.length;
				} while (branches.length > 0 && branchIndex >= branchLength)
				if (branchIndex < branchLength)
					currentItem = branch.getItemAt(branchIndex);
				else
					return null;
				
			}
			else
			{
				return result;
			}
		}
		return null; // never happen
	}
	
	//--------------------------------------------------------------------------
	//
	//  Implementation of ICollectionView: methods
	//
	//--------------------------------------------------------------------------
	public function get filterFunction():Function{return null;}
	public function set filterFunction(value:Function):void {}
	
	public function get sort():ISort{return null;}
	public function set sort(value:ISort):void {}
	
	public function createCursor():IViewCursor{return null;}
	
	public function disableAutoUpdate():void {}	
	public function enableAutoUpdate():void { }
	
	public function contains(item:Object):Boolean {
		return parentObjectsToOpenedBranches(item) || getItemIndex(item) >= 0;
	}
	
	public function openBranch(branch:IList, parentObject:TreeItem, cancelable:Boolean):void
	{
		if (parentObject && isOpen(parentObject))
			return;
		
		var treeEvent:TreeEvent;
		if (parentObject) // if parentObject == null - root node is opening
		{
			treeEvent = new TreeEvent(TreeEvent.ITEM_OPENING, false, cancelable,
				parentObject, null);
			treeEvent.opening = true;
			dispatchEvent(treeEvent);
			if (cancelable && treeEvent.isDefaultPrevented())
				return;
			
			//after default event
			parentObject.expanded = true;
		}
		
//trace("TreeDataProvider,openBrach,branch.class="+ getQualifiedClassName(branch));
		branch.addEventListener(CollectionEvent.COLLECTION_CHANGE,
			branch_collectionChangeHandler);
		
		_length += branch.length;
trace("openBranch: _length="+_length);		


		// clear untrusted area of cache
		var parentObjectIndex:int = parentObject ? getItemIndex(parentObject) : -1;
		if (parentObjectIndex >= 0 && cache.length > parentObjectIndex)
			cache.splice(parentObjectIndex, cache.length - parentObjectIndex);

		var event:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,
			false, false, CollectionEventKind.ADD, 
			parentObject ? parentObjectIndex + 1 : 0, -1, branch.toArray());
		dispatchEvent(event);

		if (parentObject)
			dispatchParentObjectUpdateEvent(parentObject, parentObjectIndex);
		
		if (parentObject) // if parentObject == null - root node is opening
		{
			treeEvent = new TreeEvent(TreeEvent.ITEM_OPEN, false, false, parentObject, null);
			dispatchEvent(treeEvent);
		}
	}
	
	private function dispatchParentObjectUpdateEvent(parentObject:Object, parentObjectIndex:int):void
	{
		var propertyChangeEvent:PropertyChangeEvent = 
			new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, 
				false, false, PropertyChangeEventKind.UPDATE, null,
				null, null, parentObject);
		var event:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,
			false, false, CollectionEventKind.UPDATE, 
			parentObjectIndex, parentObjectIndex, [ propertyChangeEvent ]);
		dispatchEvent(event);
	}

	/**
	 * Tries to close open branch.
	 * 
	 * @return true if closing succeeded.
	 */
	public function closeBranch(branch:IList, parentObject:TreeItem, cancelable:Boolean):Boolean
	{
		if (!parentObject || !isOpen(parentObject))
			return false;
		
		var treeEvent:TreeEvent;
		if (parentObject) // if parentObject == null - root node is opening
		{
			treeEvent = new TreeEvent(TreeEvent.ITEM_OPENING, false, cancelable,
				parentObject, null);
			treeEvent.opening = false;
			dispatchEvent(treeEvent);
			if (cancelable && treeEvent.isDefaultPrevented())
				return false;
			
		}
		
		if (!closeAllChildBranches(branch, parentObject, cancelable)) {
			//after default event
			parentObject.expanded = false;
			return false;
		}

		//after default event
		parentObject.expanded = false;
		
		branch.removeEventListener(CollectionEvent.COLLECTION_CHANGE,
			branch_collectionChangeHandler);

		this.refreshLength();
		

		var n:int = branch.length;
		var i:int;

		// clear untrusted area of cache
		var parentObjectIndex:int = parentObject ? getItemIndex(parentObject) : -1;
		if (parentObjectIndex >= 0 && cache.length >= parentObjectIndex)
			cache.splice(parentObjectIndex, cache.length - parentObjectIndex);
		
		var locationBase:int = parentObject ? parentObjectIndex + 1 : 0;
		for (i = n - 1; i >= 0; i--)
		{
			var event:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,
				false, false, CollectionEventKind.REMOVE, locationBase + i,
				locationBase + i, [ branch.getItemAt(i) ]);
			dispatchEvent(event);
		}
		
		if (parentObject)
			dispatchParentObjectUpdateEvent(parentObject, parentObjectIndex);
		
		if (parentObject) // if parentObject == null - root node is opening
		{
			treeEvent = new TreeEvent(TreeEvent.ITEM_CLOSE, false, false, parentObject, null);
			dispatchEvent(treeEvent);
		}
		
		return true;
	}
	
	/**
	 * Used when object that is root of open branch is removed.
	 * 
	 * @param branchStartIndex Index of branch start if it is available.
	 * If can be not available e.g. when we recieved refresh event and
	 * branch parent just dissapeared in the new version. In this case remove 
	 * event is not dispatched.
	 */
	private function removeBranch(branch:IList, parentObject:TreeItem, branchStartIndex:int = -1):void
	{
trace("remove branch, owner="+parentObject.getItemId() );
		branch.removeEventListener(CollectionEvent.COLLECTION_CHANGE,
			branch_collectionChangeHandler);
		
		var n:int = branch.length;
		var i:int;
		var event:CollectionEvent;
		for (i = 0; i < n; i++)
		{
			var item:TreeItem = branch.getItemAt(i) as TreeItem;

			//delete levelsCache[item];
			
			if (branchStartIndex >= 0)
			{
				_length--;
				event = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,
					false, false, CollectionEventKind.REMOVE, branchStartIndex,
					-1, [ item ]);
				dispatchEvent(event);
			}
			
			if (parentObjectsToOpenedBranches(item)){
				removeBranch(parentObjectsToOpenedBranches(item), item, branchStartIndex);
trace("removeBranch: _length="+_length);
			}
		}
	}
	
	public function closeAllChildBranches(branch:IList, parentObject:TreeItem, cancelable:Boolean):Boolean
	{
		var n:int = branch.length;
		var success:Boolean = true;
		for (var i:int = 0; i < n; i++)
		{
			var item:Object = branch.getItemAt(i);
			var childBranch:IList = parentObjectsToOpenedBranches(item);
			if (childBranch)
				success = closeBranch(childBranch, item as TreeItem, cancelable) && success; // order is significant
		}
		return success;
	}
	
	public function isOpen(item:TreeItem):Boolean
	{
		return item.expanded;
	}
	
	public function getItemLevel(item:TreeItem):int {
		return item.indentLevel;
	}

	public function getItemParent($item:TreeItem):TreeItem {
		if ( $item ) {
			return $item.parent;
		}
		return null;
	}

	private function iteratorTreeListNodes(til:TreeItemList, counter:Function):void {
		if (til) {
			for (var i:int = 0; i < til.length; i++ ) {
				var item:TreeItem = til.getItemAt(i) as TreeItem;
				if(item && item.expanded){
					iteratorTreeListNodes( item.childrens as TreeItemList, counter);
				}
			}
			counter(til);
		}
	}
	
	private function countTreeListNodes($branch:TreeItemList):int {
		var _len:int = 0;

		iteratorTreeListNodes($branch, 
			function(list:TreeItemList):void {
				_len += list.length;
			}
		);
		return _len;
	}
	
	private function refreshLength():void
	{
		this._length = countTreeListNodes(this.dataProvider);
//trace("refresh _length="+_length);
	}
/*
	private function refreshLength():void
	{
		var n:int = openedBranchesVector.length;
		_length = 0;
		for (var i:int = 0; i < n; i++)
		{
			_length += openedBranchesVector[i].length;
		}
	}
*/
	private function closeEmptyExpandedItem($branch:TreeItemList):void {
		if ( $branch && $branch.length>0 ) {
			for (var i:int; i < $branch.length; i++ ) {
				var $item:TreeItem = $branch.getItemAt(i) as TreeItem;
				
				if ($item) {
					if ($item.childrens && $item.childrens.length>0) {
						closeEmptyExpandedItem($item.childrens as TreeItemList);
					} else if ($item.expanded) {
						closeBranch($item.childrens, $item, false);
					}
				}
			}
		}
	}
	
	private function closeEmptyOpenBranches():void {
		closeEmptyExpandedItem(this.dataProvider);
	}
	
	private function iteratorTreeList($branch:TreeItemList, filter:Function, useFilterCondition:Boolean=false):void {
		if ( $branch && $branch.length > 0 ) {
			for (var i:int; i < $branch.length; i++ ) {
				var $item:TreeItem = $branch.getItemAt(i) as TreeItem;
				if ( $item ) {
					var f:Boolean = filter($item);
					if ( ( (useFilterCondition && f) || (!useFilterCondition) ) && 
						$item.childrens && 
						$item.childrens.length > 0) {
						iteratorTreeList($item.childrens as TreeItemList, filter, useFilterCondition);
					}
				}
			}
		}
	}

	private function removeLostBranches(currentlyRemovedObject:Object):void
	{
		var allExpandedItems:Vector.<TreeItem> = new Vector.<TreeItem>();
		iteratorTreeList(this.dataProvider, 
			function($item:TreeItem):Boolean {
				if ($item.expanded && getItemIndex($item) < 0) {
					allExpandedItems.push($item);
					return true;
				}
				return false;
			});
		
		for each (var item:TreeItem in allExpandedItems) {
			if(item != currentlyRemovedObject){
				removeBranch(parentObjectsToOpenedBranches(item), item);
trace("removeLostBranches: _length="+_length);
			}
		}
	}

	private function branchLocationToGlobalIndex(location:int, branch:IList, branchStartIndex:int):int
	{
		if (location == 0 || branch.length == 0)
			return branchStartIndex;
		
		var previousObject:Object = branch.getItemAt(Math.min(location - 1, branch.length - 1));
		while (parentObjectsToOpenedBranches(previousObject))
		{
			var childBranch:IList = parentObjectsToOpenedBranches(previousObject);
			previousObject = childBranch.getItemAt(childBranch.length - 1);
		}
		
		return getItemIndex(previousObject) + 1;
	}
	
	private function branch_collectionChangeHandler(event:CollectionEvent):void
	{
trace("branch_collectionChangeHandler, event.kind="+event.kind);		
		var parentObject:Object = openedBranchesToParentObjects(event.target);
		var branchStartIndex:int = parentObject ? getItemIndex(parentObject) + 1 : 0;
		var kind:String = event.kind;
		var items:Array = event.items;
		var item:Object;
		var n:int = items ? items.length : 0;
		var i:int;
		
		// it's a too complex task - keeping cache up to date because we recieve
		// update events after update has been made and we do not know which
		// items were removed from what indexes
		resetCache();
		
		// convert local locations to global 
		if (event.location != -1)
			event.location = branchLocationToGlobalIndex(event.location, 
				IList(event.target), branchStartIndex);
		if (event.oldLocation != -1)
			event.oldLocation = branchLocationToGlobalIndex(event.oldLocation, 
				IList(event.target), branchStartIndex);
		
		// check if some of open branches are now empty and needs to be closed
		closeEmptyOpenBranches();
//trace("branch event: after closeEmptyOpenBranches, length="+_length);
		// items that were open branches could be removed. Remove links to them
		// from internal tree structures to avoid memory leaks
		if (items[0]) {
			var iii:TreeItem = null;
			if (items[0] is PropertyChangeEvent) {
				removeLostBranches(items[0].source);
//trace("branch event: after removeLostBranches0, length="+_length);
			} else {
				removeLostBranches(items[0]);
//trace("branch event: after removeLostBranches1, length="+_length);
			}
		}
		
		//refreshLength();
		
		// check if we need to close some child object branches that have been updated/removed
		if (kind == CollectionEventKind.REMOVE || kind == CollectionEventKind.REPLACE)
		{
			// only one item can arrive
			item = items[0];
			if (parentObjectsToOpenedBranches(item)){
				removeBranch(parentObjectsToOpenedBranches(item), item as TreeItem, event.location + 1);
trace("branch REMOVE event: _length="+_length);
			}
		}
		else if (kind == CollectionEventKind.UPDATE)
		{
			var propertyEvent:PropertyChangeEvent;
			for (i = 0; i < n; i++)
			{
				propertyEvent = items[i];
				item = propertyEvent.source;
				var treeItem:TreeItem = item as TreeItem;

				var branch:IList = parentObjectsToOpenedBranches(treeItem);
				// if branch was removed or changed - close it in here
				if (branch && branch != treeItem.childrens )
					closeBranch(branch, treeItem, false);
			}
		} else if (kind == CollectionEventKind.ADD) {
			for (i = 0; i < n; i++)
			{
				item = items[i];
				var treeItem1:TreeItem = item as TreeItem;

				var branch1:IList = parentObjectsToOpenedBranches(treeItem1);
				// if branch was removed or changed - close it in here
				if (branch1 && branch1 != treeItem1.childrens )
					closeBranch(branch1, treeItem1, false);
			}
		} else if (kind == CollectionEventKind.RESET) {
			this.reset1();
		}
		
		refreshLength();
		
		dispatchEvent(event);
	}
	
}
}