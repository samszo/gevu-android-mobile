package {

import mx.collections.IList;
import mx.events.CollectionEvent;
import spark.components.DropDownList;
import spark.components.Label;

/**
 *  Subclass DropDownList and make it work like a DateField
 */
public class SparkDateField extends DropDownList
{

    private var calendarIList:CalendarIList;
    
    public function SparkDateField()
    {
        super();
        super.dataProvider = calendarIList = new CalendarIList();
        super.dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
        var d:Date = new Date();
        calendarIList.setMonthAndYear(d.month, d.fullYear);
        labelFunction = defaultDateDisplay;
        
    }
    
    private function defaultDateDisplay(item:CalendarIListDay):String
    {
        return item.date.toDateString();
    }
    
    [Bindable("change")]
    public function get selectedDate():Date
    {
        return CalendarIListDay(selectedItem).date;
    }
    public function set selectedDate(value:Date):void
    {
        calendarIList.setMonthAndYear(value.month, value.fullYear);
        var n:int = super.dataProvider.length;
        for (var i:int = 0; i < n; i++)
        {
            if (CalendarIListDay(dataProvider[i]).date.day == value.day)
                selectedIndex = i;
        }
    }
    
    [SkinPart(required="false")]
    public var current:Label;
    
    private function collectionChangeHandler(event:CollectionEvent):void
    {
        if (current)
            current.text = monthNames[calendarIList.month] + " " + 
                calendarIList.year.toString(); 
    }

    private static const monthNames:Vector.<String> = 
        Vector.<String>([
            "January",
            "February",
            "March",
            "April",
            "May",
            "June",
            "July",
            "August",
            "September",
            "October",
            "November",
            "December"
        ]);
    
    // don't allow anyone to set our custom DP
    override public function set dataProvider(value:IList):void
    {
        
    }
    
    /**
     *  @private
     */
    override protected function partAdded(partName:String, instance:Object):void
    {
        super.partAdded(partName, instance);
        
        if (instance == current)
            current.text = monthNames[calendarIList.month] + " " + 
                calendarIList.year.toString(); 
    }

}

}
