package com.sparkTree
{
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;
import flash.utils.getQualifiedClassName;
import mx.collections.ListCollectionView;

import mx.collections.IList;
import mx.core.ClassFactory;
import mx.core.FlexGlobals;
import mx.core.IVisualElement;
import mx.core.mx_internal;
import mx.events.DragEvent;

import spark.components.List;

use namespace mx_internal;

//--------------------------------------
//  Events
//--------------------------------------

/**
 *  Dispatched when a branch is closed or collapsed.
 */
[Event(name="itemClose", type="com.sparkTree.TreeEvent")]

/**
 *  Dispatched when a branch is opened or expanded.
 */
[Event(name="itemOpen", type="com.sparkTree.TreeEvent")]

/**
 *  Dispatched when a branch open or close is initiated.
 */
[Event(name="itemOpening", type="com.sparkTree.TreeEvent")]

//--------------------------------------
//  Styles
//--------------------------------------

/**
 *  Specifies the icon that is displayed next to a parent item that is open so that its
 *  children are displayed.
 *
 *  The default value is the "TreeDisclosureOpen" symbol in the Assets.swf file.
 */
[Style(name="disclosureOpenIcon", type="Class", format="EmbeddedFile", inherit="no")]

/**
 *  Specifies the icon that is displayed next to a parent item that is closed so that its
 *  children are not displayed (the subtree is collapsed).
 *
 *  The default value is the "TreeDisclosureClosed" symbol in the Assets.swf file.
 */
[Style(name="disclosureClosedIcon", type="Class", format="EmbeddedFile", inherit="no")]
/**
 * Indentation for each tree level, in pixels. The default value is 17.
 */
[Style(name="indentation", type="Number", inherit="no", theme="spark")]

/**
 *  Specifies the folder open icon for a branch item of the tree.
 */
[Style(name="folderOpenIcon", type="Class", format="EmbeddedFile", inherit="no")]

/**
 *  Specifies the folder closed icon for a branch item of the tree.
 */
[Style(name="folderClosedIcon", type="Class", format="EmbeddedFile", inherit="no")]

/**
 *  Specifies the default icon for a leaf item.
 */
[Style(name="defaultLeafIcon", type="Class", format="EmbeddedFile", inherit="no")]

/**
 *  Color of the text when the user rolls over a row.
 */
[Style(name="textRollOverColor", type="uint", format="Color", inherit="yes")]

/**
 *  Color of the text when the user selects a row.
 */
[Style(name="textSelectedColor", type="uint", format="Color", inherit="yes")]
/**
 * Custom Spark Tree that is based on Spark List. Supports most of MX Tree
 * features and does not have it's bugs.
 */
public class Tree extends List
{
	
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	
	public function Tree()
	{
		super();

		setStyle("indentation", 17);
		setStyle("disclosureOpenIcon", disclosureOpenIcon);
		setStyle("disclosureClosedIcon", disclosureClosedIcon);
		setStyle("folderOpenIcon", folderOpenIcon);
		setStyle("folderClosedIcon", folderClosedIcon);
		setStyle("defaultLeafIcon", defaultLeafIcon);

		setStyle("rollOverColor", "0xf0ef84");
		
		_treeItemsManager = new TreeItemCollection();
		
		itemRenderer = new ClassFactory(DefaultTreeItemRenderer);
	}
	
	private var _treeItemsManager:TreeItemCollection;
	//--------------------------------------------------------------------------
	//
	//  Variables
	//
	//--------------------------------------------------------------------------
	
	[Embed("../../../assets/disclosureOpenIcon.png")]
	private var disclosureOpenIcon:Class;
	
	[Embed("../../../assets/disclosureClosedIcon.png")]
	private var disclosureClosedIcon:Class;
	
	[Embed("../../../assets/folderOpenIcon.png")]
	private var folderOpenIcon:Class;
	
	[Embed("../../../assets/folderClosedIcon.png")]
	private var folderClosedIcon:Class;
	
	[Embed("../../../assets/defaultLeafIcon.png")]
	private var defaultLeafIcon:Class;
	
	private var refreshRenderersCalled:Boolean = false;
	
	private var renderersToRefresh:Vector.<ITreeItemRenderer> = new Vector.<ITreeItemRenderer>();
	

	//----------------------------------
	//  dataProvider
	//----------------------------------
	
	private var _treeDataProvider:TreeDataProvider;
	
	override public function get dataProvider():IList
	{
		return _treeDataProvider;
	}
	
	//DP = data provider
	private var _originalDP:IList = null;
	
	override public function set dataProvider(value:IList):void {
		if ( _originalDP === value ) {
trace("Tree set dataProvider: _originalDP === value");			
			return;
		}
		
		_originalDP = value;
		
		var _tmpTreeDP:TreeDataProvider;
		if (_originalDP)
		{
			_treeItemsManager.removeAll();
			
			//因为 _treeItemsManager 已经被 set 了很多的属性, 所以不能重新new
			//_treeItemsManager = new TreeItemCollection();
			
			_tmpTreeDP = _originalDP is TreeDataProvider ? TreeDataProvider(value) : new TreeDataProvider(this._treeItemsManager,_originalDP);
		}
		
		if (_treeDataProvider) {//old
			_treeDataProvider.removeEventListener(TreeEvent.ITEM_CLOSE, dataProvider_someHandler);
			_treeDataProvider.removeEventListener(TreeEvent.ITEM_OPEN, dataProvider_someHandler);
			_treeDataProvider.removeEventListener(TreeEvent.ITEM_OPENING, dataProvider_someHandler);
			_treeDataProvider.detach();
		}
		
		_treeDataProvider = _tmpTreeDP;
		super.dataProvider = _treeDataProvider;
		
		if (_treeDataProvider) {
			_treeDataProvider.addEventListener(TreeEvent.ITEM_CLOSE, dataProvider_someHandler);
			_treeDataProvider.addEventListener(TreeEvent.ITEM_OPEN, dataProvider_someHandler);
			_treeDataProvider.addEventListener(TreeEvent.ITEM_OPENING, dataProvider_someHandler);
		}
	}
	
	//----------------------------------
	//  iconField
	//----------------------------------
	
	private var _iconField:String = "icon";
	
	[Bindable("iconFieldChange")]
	public function get iconField():String
	{
		return _iconField;
	}
	
	public function set iconField(value:String):void
	{
		if (_iconField == value)
			return;
		
		_iconField = value;
		refreshRenderers();
		dispatchEvent(new Event("iconFieldChange"));
	}
	
	//----------------------------------
	//  iconOpenField
	//----------------------------------
	
	private var _iconOpenField:String = "icon";
	
	[Bindable("iconOpenFieldChange")]
	/**
	 * Field that will be searched for icon when showing open folder item.
	 */
	public function get iconOpenField():String
	{
		return _iconOpenField;
	}
	
	public function set iconOpenField(value:String):void
	{
		if (_iconOpenField == value)
			return;
		
		_iconOpenField = value;
		refreshRenderers();
		dispatchEvent(new Event("iconOpenFieldChange"));
	}
	
	//----------------------------------
	//  iconFunction
	//----------------------------------
	
	private var _iconFunction:Function;
	
	[Bindable("iconFunctionChange")]
	/**
	 * Icon function. Signature <code>function(item:Object, isOpen:Boolean, isBranch:Boolean):Class</code>.
	 */
	public function get iconFunction():Function
	{
		return _iconFunction;
	}
	
	public function set iconFunction(value:Function):void
	{
		if (_iconFunction == value)
			return;
		
		_iconFunction = value;
		refreshRenderers();
		dispatchEvent(new Event("iconFunctionChange"));
	}
	
	//----------------------------------
	//  iconsVisible
	//----------------------------------
	
	private var _iconsVisible:Boolean = true;
	
	[Bindable("iconsVisibleChange")]
	/**
	 * Field that will be searched for icon when showing open folder item.
	 */
	public function get iconsVisible():Boolean
	{
		return _iconsVisible;
	}
	
	public function set iconsVisible(value:Boolean):void
	{
		if (_iconsVisible == value)
			return;
		
		_iconsVisible = value;
		refreshRenderers();
		dispatchEvent(new Event("iconsVisibleChange"));
	}
	
	//----------------------------------
	//  useTextColors
	//----------------------------------
	
	private var _useTextColors:Boolean = true;
	
	[Bindable("useTextColorsChange")]
	/**
	 * MX components use "textRollOverColor" and "textSelectedColor" while Spark
	 * do not. Set this property to <code>true</code> to use them in tree.
	 */
	public function get useTextColors():Boolean
	{
		return _useTextColors;
	}
	
	public function set useTextColors(value:Boolean):void
	{
		if (_useTextColors == value)
			return;
		
		_useTextColors = value;
		refreshRenderers();
		dispatchEvent(new Event("useTextColorsChange"));
	}

	//--------------------------------------------------------------------------
	//
	//  Overriden methods
	//
	//--------------------------------------------------------------------------
	
	//here, data is TreeItem
	override public function updateRenderer(renderer:IVisualElement, itemIndex:int, $data:Object):void
	{
//trace("Tree updateRenderer, index="+itemIndex);		
		var item:TreeItem;
		if ($data is TreeItem) {
			item = $data as TreeItem;
		} else {
			item = this._treeItemsManager.find($data);
		}
		
		itemIndex = _treeDataProvider.getItemIndex(item);
		
		super.updateRenderer(renderer, itemIndex, item);
		
		var treeItemRenderer:ITreeItemRenderer = ITreeItemRenderer(renderer);
		treeItemRenderer.level = item.indentLevel;
		treeItemRenderer.isBranch = true;
		treeItemRenderer.isLeaf = false;
		treeItemRenderer.hasChildren = item.hasChildren();
		treeItemRenderer.isOpen = item.expanded;
		treeItemRenderer.icon = _iconsVisible ? getIcon(item) : null;
		treeItemRenderer.disclosureIcon = item.isBranch()? getDisclosureIcon(item):null;
	}
	
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		
		// refresh all renderers or only some of them
		var n:int;
		var i:int;
		var renderer:ITreeItemRenderer;
		if (refreshRenderersCalled)
		{
			refreshRenderersCalled = false;
			n = dataGroup.numElements;
			for (i = 0; i < n; i++)
			{
				renderer = dataGroup.getElementAt(i) as ITreeItemRenderer;
				if (renderer)
					updateRenderer(renderer, renderer.itemIndex, renderer.data);
			}
		}
		else if (renderersToRefresh.length > 0)
		{
			n = renderersToRefresh.length;
			for (i = 0; i < n; i++)
			{
				renderer = renderersToRefresh[i];
				updateRenderer(renderer, renderer.itemIndex, renderer.data);
			}
		}
		if (renderersToRefresh.length > 0)
			renderersToRefresh.splice(0, renderersToRefresh.length);
	}
	
	/**
	 * Handle <code>Keyboard.LEFT</code> and <code>Keyboard.RIGHT</code> as tree
	 * node collapsing and expanding.
	 */
	override protected function adjustSelectionAndCaretUponNavigation(event:KeyboardEvent):void
	{
		super.adjustSelectionAndCaretUponNavigation(event);
		
		if (!selectedItem)
			return;
		
		var navigationUnit:uint = mapKeycodeForLayoutDirection(event);
		if (navigationUnit == Keyboard.LEFT)
		{
			if (_treeDataProvider.isOpen(selectedItem))
			{
				expandItem(selectedItem, false);
			}
			else
			{
				var parent:Object = _treeDataProvider.getItemParent(selectedItem);
				if (parent)
					selectedItem = parent;
			}
		}
		else if (navigationUnit == Keyboard.RIGHT)
		{
			expandItem(selectedItem);
		}
	}
	
	
	override public function itemToLabel(item:Object):String {
		if(item){
			return super.itemToLabel((item as TreeItem).source);
		} else {
			return super.itemToLabel(null);
		}
	}
	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------
	
	public function expandItem($item:Object, open:Boolean = true, cancelable:Boolean = true):void
	{
		if ( $item ) {
			var item:TreeItem;
			if ( ! ($item is TreeItem) ) {
				item = this._treeItemsManager.find($item);
			} else {
				item = ($item as TreeItem);
			}
			if ( item.hasChildren())
			{
				var children:IList = item.childrens;
				if (open)
					_treeDataProvider.openBranch(children, item, cancelable);
				else
					_treeDataProvider.closeBranch(children, item, cancelable);
			}
		}
//trace("expandItem, item.clas="+getQualifiedClassName(item));
		
	}
	
	public function getDisclosureIcon(item:TreeItem):Class{
		var icon:Class = getStyle(item.expanded ? "disclosureOpenIcon" : "disclosureClosedIcon");

		return icon;
	}
	
	public function getIcon(item:TreeItem):Class
	{
//trace("getIcon, item.clas="+getQualifiedClassName(item));
		var isBranch:Boolean = (item as TreeItem).isBranch();
		var isOpen:Boolean = isBranch ? item.expanded : false;
		var icon:Class = getOwnItemIcon(item, isOpen, isBranch);
		if (icon)
			return icon;
		
		if (isBranch)
			icon = getStyle(isOpen ? "folderOpenIcon" : "folderClosedIcon");
		else
			icon = getStyle("defaultLeafIcon");
		return icon;
	}
	
	public function getOwnItemIcon(item:TreeItem, isOpen:* = null, isBranch:* = null):Class
	{
		if (isOpen === null)
			isOpen = item.expanded;
		if (isBranch === null)
			isBranch = (item as TreeItem).isBranch();
		
		var icon:Class;
		if (!icon && _iconFunction != null)
			icon = _iconFunction(item, isOpen, isBranch);
		if (icon)
			return icon;
		
		if (isOpen && _iconOpenField)
			icon = item.getIcon(_iconOpenField);
		else if (!isOpen && _iconField)
			icon = item.getIcon(_iconField);
		return icon;
	}
	
	public function refreshRenderers():void
	{
		refreshRenderersCalled = true;
		invalidateDisplayList();
	}
	
	public function refreshRenderer(renderer:ITreeItemRenderer):void
	{
		renderersToRefresh.push(renderer);
		invalidateDisplayList();
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overriden event handlers
	//
	//--------------------------------------------------------------------------

	override protected function dragDropHandler(event:DragEvent):void
	{
		// list does not take in account that removing an open node while drag
		// can cause list to loose more than 1 element. When element is dropped,
		// to big index can be specified in dataProvider.addItemAt()
		if (_treeDataProvider)
			_treeDataProvider.allowIncorrectIndexes = true;
		
		super.dragDropHandler(event);
		
		if (_treeDataProvider)
			_treeDataProvider.allowIncorrectIndexes = false;
	}
	
	//--------------------------------------------------------------------------
	//
	//  Event handlers
	//
	//--------------------------------------------------------------------------

	private function dataProvider_someHandler(event:TreeEvent):void
	{
		var clonedEvent:TreeEvent = TreeEvent(event.clone());
		if (dataGroup)
		{
			// find corresponding item renderer
			var n:int = dataGroup.numElements;
			for (var i:int = 0; i < n; i++)
			{
				var renderer:ITreeItemRenderer = dataGroup.getElementAt(i) as ITreeItemRenderer;
				if (renderer && renderer.data == event.item)
					clonedEvent.itemRenderer = renderer;
			}
		}
		dispatchEvent(clonedEvent);
		if (clonedEvent.isDefaultPrevented())
			event.preventDefault();
	}

	//--------------------------------------------------------------------------
	//
	//  item identify
	//
	//--------------------------------------------------------------------------
	
	public function get allowAutoIdentify():Boolean {
		return this._treeItemsManager.allowAutoIdentify;
	}
	
	public function set allowAutoIdentify(f:Boolean):void {
		this._treeItemsManager.allowAutoIdentify = f;
	}
	
	public function get itemIdentifyField():String {
		return this._treeItemsManager.itemIdentifyField;
	}
	
	public function set itemIdentifyField(field:String):void {
		this._treeItemsManager.itemIdentifyField = field;
trace("Tree set itemIdentifyField="+field);		
	}
	
	public function get itemIdentifyFunction():Function {
		return this._treeItemsManager.itemIdentifyFunction;
	}
	
	public function set itemIdentifyFunction(func:Function):void {
		this._treeItemsManager.itemIdentifyFunction = func;
	}
	
	//whether allow some treeitem can not be selected
	public var allowItemDisSelection:Boolean = false;
	//=========== selectedable 
	override mx_internal function setSelectedIndex(value:int, dispatchChangeEvent:Boolean = false, changeCaret:Boolean = true):void
	{
			if ( ! allowItemDisSelection ) {
				super.setSelectedIndex(value, dispatchChangeEvent);
				return;
			}
			//trace("setSelectedIndex");
			if (value == selectedIndex)
				return;

			if (value >= 0 && value < _treeDataProvider.length){
				if (_treeDataProvider.getItemAt(value).enableSelection != false){
					
					if (dispatchChangeEvent)
						dispatchChangeAfterSelection = dispatchChangeEvent;
					
					_proposedSelectedIndex = value;
					invalidateProperties();
				}
			} else {
				if (dispatchChangeEvent)
					dispatchChangeAfterSelection = dispatchChangeEvent;
				
				_proposedSelectedIndex = value;
				invalidateProperties();
			}
		}
		
		/**
		 * Override the setSelectedIndex() mx_internal method to not select an item that
		 * has selectionEnabled=false.
		 */
		//override mx_internal function setSelectedIndices(value:Vector.<int>, dispatchChangeEvent:Boolean = false):void
		override mx_internal function setSelectedIndices(value:Vector.<int>, dispatchChangeEvent:Boolean = false, changeCaret:Boolean = true):void
		{
			if ( ! allowItemDisSelection ) {
				super.setSelectedIndices(value, dispatchChangeEvent);
				return;
			}
			
			//trace("setSelectedIndex");
			var newValue:Vector.<int> = new Vector.<int>;
			// take out indices that are on items that have selectionEnabled=false
			
			for(var i:int = 0; i < value.length; i++)
			{
				
				var item:TreeItem = _treeDataProvider.getItemAt(value[i]) as TreeItem;
				
				if (item.source.enableSelection == false){
					continue;
				}
				
				newValue.push(value[i]);
			}
			
			super.setSelectedIndices(newValue, dispatchChangeEvent);
		}
}
}
