/**
 * @author Joris Timmerman
 * @version 1.0 - beta
 * 
 * FLVRecorder - Record a series of BitmapData to an FLV-file
 * Build by Joris Timmerman, based upon encoding-algorithms from SimpleFLVWriter by ZeroPointNine
 * 
 * SPECIAL THANKS TO SIMPLEFLVWRITER BY ZERO POINT NINE
 * NOT FOR COMMERCIAL USE, EXCEPT BoulevArt nv OR WRITTEN PERMISSION BY BoulevArt nv OR JORIS TIMMERMAN
 * 
 * USED CODEC: SCREEN VIDEO
 */

package be.boulevart.video
{
	import be.boulevart.bitmapencoding.JPGEncoder;
	import be.boulevart.events.FLVRecorderEvent;
	import be.boulevart.threading.PseudoThread;
	
	import flash.display.*;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.*;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.ByteArray;
	
	import mx.managers.ISystemManager;
	
	public class FLVRecorder extends EventDispatcher
	{
//- PRIVATE & PROTECTED VARIABLES -------------------------------------------------------------------------

		private var frameWidth:int;
		private var frameHeight:int;
		private var frameRate:Number;
		private var duration:Number;

		private var fs:FileStream;
		
		private var f:File; //FLV file
		private var tft:File;//temp file
		
		private const blockWidth:int = 32;
		private const blockHeight:int = 32;
		private var previousTagSize:uint = 0;
		private var iteration:int = 0;
		
		private var _isOpen:Boolean=false
		private var _isRecording:Boolean=false
		
		private var total:int=0
		private var curr:int=0
		private var startTime:Date=null
		
		private var _enableCompression:Boolean=false
		private var _codec:int=3
		
		// singleton instance
		private static var _instance:FLVRecorder;
		private static var _allowInstance:Boolean;
		
		public var systemManager:ISystemManager
		
//- PUBLIC & INTERNAL VARIABLES ---------------------------------------------------------------------------
		
		public static const DEFAULT_NAME:String = "FLVRecorder";
		
//- CONSTRUCTOR	-------------------------------------------------------------------------------------------
	
		// singleton instance of FLVRecorder
		public static function getInstance():FLVRecorder 
		{
			if (FLVRecorder._instance == null)
			{
				FLVRecorder._allowInstance = true;
				FLVRecorder._instance = new FLVRecorder();
				FLVRecorder._allowInstance = false;
			}
			
			return FLVRecorder._instance;
		}
		
		public function FLVRecorder() 
		{
			if (!FLVRecorder._allowInstance)
			{
				throw new Error("Error: Use FLVRecorder.getInstance() instead of the new keyword.");
			}
		}
		
//-  METHODS -----------------------------------------------------------------------------
	/**
	 * 
	 * @param file File that references to the FLV-file that is going to be written to.  (var file:File=new File("url"))
	 * @param width Video width
	 * @param height Video height
	 * @param fps Framerate
	 * @param systemMgr Systemmanager, needed for saving the flv-file and not blank out the app
	 * @param durationInSeconds Duration of vidoe, in seconds, if not filled in, will be automaticly determined
	 * 
	 */	
	public function setTarget(file:File, width:int, height:int, fps:Number, systemMgr:ISystemManager,durationInSeconds:Number=0):void
		{
			/*
				Parameters:
				
				file: De 'file' waarnaar geschreven moet worden (var file:File=new File("url"))
				height: Video hoogte
				width: Video breedte
				fps: Framerate
				durationInSeconds: Duur van de video, in secondjes, optioneel, indien niet ingevuld, wordt automatisch bepaald
			*/
			
			
			frameWidth = width;
			frameHeight = height;
			frameRate = fps/2;
			duration = durationInSeconds;
			
			systemManager=systemMgr
			
			f = file;
			
		}
		
		private function writeFrame(o:Object):void
		{	
			if(isOpen){
				var bmpd:BitmapData=o.bmp as BitmapData
				curr++
				dispatchEvent(new FLVRecorderEvent(FLVRecorderEvent.PROGRESS,"",curr/total))
				
				fs.writeUnsignedInt( previousTagSize )
				flvTagVideo(bmpd)
				bmpd.dispose()
			}
			
			
			
		}
		
		/**
		 *Clear the class after unsuccesfull shutdown, like abrubt stopping while saving 
		 * 
		 */		
		public function clear():void{
			try{
				if (isOpen){
					fs.close()
					f=null
					_isOpen=false
				}
				
				if(isRecording){
					_isRecording=false
					try{
						tft.deleteFileAsync()
					}catch(e:Error){}
				}
				
				tft=null
				total=0
				curr=0
				duration=0
				startTime=null

				System.gc()
			}catch(e:Error){}
		}
		
		/**
		 *Add a bitmapdata frame to the movie
		 * @param bmpd The frame as BitmapData
		 * 
		 */		
		public function saveFrame(bmpd:BitmapData):void{
				if(startTime==null){
					startTime=new Date()
				}
				_isRecording=true
				total++
			
				writeFrames(bmpd)
			
		}
		
		private function writeFrames(bd:BitmapData):void{
			if(isRecording){
				
				if(tft==null){
					tft=File.createTempFile()
				}
				
				var fls:FileStream=new FileStream()
				
				fls.open(tft, FileMode.APPEND);
				var target:ByteArray=bd.getPixels(new Rectangle(0,0,frameWidth,frameHeight))
				//target.compress()
				fls.writeObject(target)
				fls.truncate()
				fls.close()
			
				bd.dispose()
			}
		}	

		
		/**
		 * Takes a screenshot of the component, movieclip or sprite inputted
		 * @param source: instance of the component to be captured
		 * 
		 */		
		public function captureComponent(source:DisplayObject):void {
			var bmd:BitmapData = new BitmapData(source.width, source.height);
			bmd.draw(source);
			saveSmoothedFrame(bmd)
		}
		
		
		/**
		 * Saves the bitmap and smooths it
		 * @param bmp bitmap to be saved
		 * 
		 */		
		public function saveSmoothedBitmapFrame(bmp:Bitmap):void
		{
			bmp.smoothing=true
			saveFrame(bmp.bitmapData)
			bmp=null
		}
		/**
		 *Saves a bitmapdaat frame and smooths it 
		 * @param bmpd bitmapdata to be saved
		 * 
		 */		
		public function saveSmoothedFrame(bmpd:BitmapData):void
		{
			var bmp:Bitmap=new Bitmap(bmpd)
			bmp.smoothing=true
			saveFrame(bmp.bitmapData)
			bmp=null
		}
		
		
		/**
		 *Stops the recording and starts the saving 
		 * 
		 */		
		public function stopRecording():void
		{
			_isRecording=false
			
			fs=new FileStream();
			fs.openAsync(f, FileMode.WRITE);
			
			_isOpen=true
			
			if(this.duration==0){
				var now:Date=new Date()
				this.duration=(now.getTime()-startTime.getTime())/1000
			}
			
			// header aanmaken
			fs.writeBytes( header() );
			
			// metadata tag
			fs.writeUnsignedInt( previousTagSize );
			fs.writeBytes( flvTagOnMetaData() );
			
			
			new PseudoThread(systemManager,doStop)
		}	
		/**
		 * Saves a bytearray from a bitmap
		 * @param bd bytearray to be saved
		 * 
		 */	
		public function saveByteFrame(bd:ByteArray ):void{
			if(isRecording){
				
				if(tft==null){
					tft=File.createTempFile()
				}
			//	bd.compress()
				
				var fls:FileStream=new FileStream()
				
				fls.open(tft, FileMode.APPEND);
				fls.writeObject(bd)
				fls.truncate()
				fls.close()
			}
		}
		
		private function doStop():void{

			dispatchEvent(new FLVRecorderEvent(FLVRecorderEvent.FLV_START_CREATION))
			
			var s:FileStream=new FileStream()
			s.open(tft,FileMode.READ)
				
			while(s.bytesAvailable){
				var ba:ByteArray=s.readObject() as ByteArray
				///if(!isCompressed){
					var frame:BitmapData=new BitmapData(frameWidth,frameHeight)
			//		ba.uncompress()
					frame.setPixels(new Rectangle(0,0,frameWidth,frameHeight),ba)
					
					ba=null
					new PseudoThread(systemManager,writeFrame,{bmp:frame})	
				/*}else{
					var loader:Loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event){
						var frame:BitmapData = Bitmap(e.target.content).bitmapData						
						new PseudoThread(systemManager,writeFrame,{bmp:frame})	
					})
					loader.loadBytes(ba);	
					
				}*/
			}
			
			s.close()
		}
	
				
		private function header():ByteArray
		{
			var ba:ByteArray = new ByteArray();
			ba.writeByte(0x46) // 'F'
			ba.writeByte(0x4C) // 'L'
			ba.writeByte(0x56) // 'V'
			ba.writeByte(0x01) // Version 1
			ba.writeByte(0x01) // misc flags - video stream only
			ba.writeUnsignedInt(0x09) // header length
			return ba;
		}		
		
		private function flvTagVideo(b:BitmapData):void
		{
			if(_enableCompression){
			var enc:JPGEncoder=new JPGEncoder()
			
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event){
				var decodedBitmapData:BitmapData = Bitmap(e.target.content).bitmapData
				var tag:ByteArray = new ByteArray();
				var dat:ByteArray = videoData(decodedBitmapData);
				var timeStamp:uint = uint(1000/frameRate * iteration++);
	
				// tag 'header'
				tag.writeByte( 0x09 ); 					// tagType = video
				writeUI24(tag, dat.length); 			// data size
				writeUI24(tag, timeStamp);				// timestamp in ms
				tag.writeByte(0);		 				// timestamp extended, not using *** 
				writeUI24(tag, 0);						// streamID always 0
				
				// videodata			
				tag.writeBytes( dat );
				
				previousTagSize = tag.length;
			
				fs.writeBytes( tag )
				decodedBitmapData.dispose()
				b.dispose()
				if(curr==total){
					dispatchEvent(new FLVRecorderEvent(FLVRecorderEvent.FLV_CREATED,f.url))
					clear()
				}
			})
			loader.loadBytes(enc.encode(b));
			}else{
			
				var tag:ByteArray = new ByteArray();
				var dat:ByteArray = videoData(b);
				var timeStamp:uint = uint(1000/frameRate * iteration++);
	
				// tag 'header'
				tag.writeByte( 0x09 ); 					// tagType = video
				writeUI24(tag, dat.length); 			// data size
				writeUI24(tag, timeStamp);				// timestamp in ms
				tag.writeByte(0);		 				// timestamp extended, not using *** 
				writeUI24(tag, 0);						// streamID always 0
				
				// videodata			
				tag.writeBytes( dat );
				
				previousTagSize = tag.length;
			
				fs.writeBytes( tag )
				b.dispose()
				if(curr==total){
					dispatchEvent(new FLVRecorderEvent(FLVRecorderEvent.FLV_CREATED,f.url))
					clear()
				}
			}
		}
		
		private function videoData(b:BitmapData):ByteArray
		{
			//CPU INTENSIEVE FUNCTIE:
			
			var v:ByteArray = new ByteArray;
			
			// VIDEODATA 'header'
			v.writeByte(0x13); // frametype (1) + codecid (3)
			
			// SCREENVIDEOPACKET 'header'			
			// blockwidth/16-1 (4bits) + imagewidth (12bits)
			writeUI4_12(v, int(blockWidth/16) - 1,  frameWidth);
			// blockheight/16-1 (4bits) + imageheight (12bits)
			writeUI4_12(v, int(blockHeight/16) - 1, frameHeight);			

			// VIDEODATA > SCREENVIDEOPACKET > IMAGEBLOCKS:

			var yMax:int = int(frameHeight/blockHeight);
			var yRemainder:int = frameHeight % blockHeight; 
			if (yRemainder > 0) yMax += 1;

			var xMax:int = int(frameWidth/blockWidth);
			var xRemainder:int = frameWidth % blockWidth;				
			if (xRemainder > 0) xMax += 1;
				
			for (var y1:int = 0; y1 < yMax; y1++)
			{
				for (var x1:int = 0; x1 < xMax; x1++) 
				{
					// create block
					var block:ByteArray = new ByteArray();
					
					var yLimit:int = blockHeight;	
					if (yRemainder > 0 && y1 + 1 == yMax) yLimit = yRemainder;

					for (var y2:int = 0; y2 < yLimit; y2++) 
					{
						var xLimit:int = blockWidth;
						if (xRemainder > 0 && x1 + 1 == xMax) xLimit = xRemainder;
						
						for (var x2:int = 0; x2 < xLimit; x2++) 
						{
							var px:int = (x1 * blockWidth) + x2;
							var py:int = frameHeight - ((y1 * blockHeight) + y2); // (flv's save from bottom to top)
							var p:uint = b.getPixel(px, py);
							
							//problem point..
							block.writeByte( p & 0xff ); 		// blue	
							block.writeByte( p >> 8 & 0xff ); 	// green
							block.writeByte( p >> 16 ); 		// red
							//..problem point
						}
					}
					block.compress();

					writeUI16(v, block.length); // write block length (UI16)
					v.writeBytes( block ); // write block
				}
			}
			
			b.dispose()
			return v;
		}

		private function flvTagOnMetaData():ByteArray
		{
			var tag:ByteArray = new ByteArray();
			var dat:ByteArray = metaData();

			// tag 'header'
			tag.writeByte( 18 ); 					// tagType = script data
			writeUI24(tag, dat.length); 			// data size
			writeUI24(tag, 0);						// timestamp should be 0 for onMetaData tag
			tag.writeByte(0);						// timestamp extended
			writeUI24(tag, 0);						// streamID always 0
			
			// data tag		
			tag.writeBytes( dat );
			
			previousTagSize = tag.length;
			return tag;
		}

		private function metaData():ByteArray
		{
		
			var b:ByteArray = new ByteArray();
			
			b.writeByte(2);	
		
			writeUI16(b, "onMetaData".length); // StringLength
			b.writeUTFBytes( "onMetaData" ); // StringData
		
			
			b.writeByte(8); // Type (ECMA array = 8)
			b.writeUnsignedInt(7) // // Elements in array
		
			
			if (duration > 0) {
				writeUI16(b, "duration".length);
				b.writeUTFBytes("duration");
				b.writeByte(0); 
				b.writeDouble(duration);
			}
			
			writeUI16(b, "width".length);
			b.writeUTFBytes("width");
			b.writeByte(0); 
			b.writeDouble(frameWidth);

			writeUI16(b, "height".length);
			b.writeUTFBytes("height");
			b.writeByte(0); 
			b.writeDouble(frameHeight);

			writeUI16(b, "framerate".length);
			b.writeUTFBytes("framerate");
			b.writeByte(0); 
			b.writeDouble(frameRate);

			writeUI16(b, "videocodecid".length);
			b.writeUTFBytes("videocodecid");
			b.writeByte(0); 
			b.writeDouble(codec); // 'Screen Video' = 3

			writeUI16(b, "canSeekToEnd".length);
			b.writeUTFBytes("canSeekToEnd");
			b.writeByte(1); 
			b.writeByte(int(true));

			var mdc:String = "Build with FLVRecorder by Joris Timmerman (BoulevArt nv), flv-writing algorithms from SimpleFLVWriter by ZeroPointNine";			
			writeUI16(b, "metadatacreator".length);
			b.writeUTFBytes("metadatacreator");
			b.writeByte(2); 
			writeUI16(b, mdc.length);
			b.writeUTFBytes(mdc);
			
			writeUI24(b, 9);
		
			return b;			
		}

		private function writeUI24(stream:*, p:uint):void
		{
			var byte1:int = p >> 16;
			var byte2:int = p >> 8 & 0xff;
			var byte3:int = p & 0xff;
			stream.writeByte(byte1);
			stream.writeByte(byte2);
			stream.writeByte(byte3);
		}
		
		private function writeUI16(stream:*, p:uint):void
		{
			stream.writeByte( p >> 8 )
			stream.writeByte( p & 0xff );			
		}

		private function writeUI4_12(stream:*, p1:uint, p2:uint):void
		{
			// writes a 4-bit value followed by a 12-bit value in two sequential bytes

			var byte1a:int = p1 << 4;
			var byte1b:int = p2 >> 8;
			var byte1:int = byte1a + byte1b;
			var byte2:int = p2 & 0xff;

			stream.writeByte(byte1);
			stream.writeByte(byte2);
		}		
	
//- EVENT HANDLERS ----------------------------------------------------------------------------------------
	
		
	
//- GETTERS & SETTERS -------------------------------------------------------------------------------------
	
		
		/**
		 * 
		 * @return if FileStream to FLV-file is open
		 * 
		 */		
		public function get isOpen():Boolean{
			return this._isOpen
		}
		
		/**
		 * 
		 * @return Compression is enabled or not
		 * 
		 */		
		public function get enableCompression():Boolean{
			return this._enableCompression
		}
		
		/**
		 * 
		 * Sets Compression enabled or not
		 * 
		 */		
		public function set enableCompression(value:Boolean):void{
			 this._enableCompression=value
		}
		
		/**
		 * 
		 * @return Codec that has been set
		 * 
		 */		
		public function get codec():int{
			return this._codec
		}
		
		/**
		 * 
		 * Sets codec, use the FLVRecorderCodecs constants
		 * 
		 */		
		public function set codec(value:int):void{
			 this._codec=value
		}
		
		/**
		 * 
		 * @return Class is recording bitmapdata to temp file
		 * 
		 */		
		public function get isRecording():Boolean{
			return this._isRecording
		}
	
//- HELPERS -----------------------------------------------------------------------------------------------
	
		public override function toString():String
		{
			return "be.boulevart.video.FLVRecorder";
		}
	
//- END CLASS ---------------------------------------------------------------------------------------------
	}
}