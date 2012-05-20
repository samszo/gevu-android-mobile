package com.sparkTree 
{
	import mx.collections.XMLListAdapter;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;

	public class XMLList1 extends XMLListAdapter
	{
		
		public function XMLList1(source:XMLList=null)
		{
			super(source);
		}
		
		override public function xmlNotification(currentTarget:Object, type:String, target:Object, value:Object, detail:Object):void 
		{
			if (currentTarget !== target) {	
				return;
			} else if (type === "attributeAdded") {
				return;
			} else if (type === "attributeChanged") {
				return;
			} else if (type === "attributeRemoved") {
				return;
			} else {

//trace("xmlNotification, currentTarget===target");
//trace("type=" + type);
/*
if(value && (value is XML) ) {
trace("value=" + value.toXMLString());
} else {
trace("value=" + value);
}

trace("target=" + target);

*/
			}
			super.xmlNotification(currentTarget, type, target, value, detail);
		}
		
	}
}