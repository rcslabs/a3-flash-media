package ru.rcslabs.components
{
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	
	import mx.logging.Log;
	
	import ru.rcslabs.utils.Logger;
	
	public class ImageLoader extends Sprite
	{
		private var loader:Loader;
		
		private var url:String;
		
		public function ImageLoader()
		{
			super();		
		}
		
		public function unload():void
		{
			if(loader){loader.unload();}
		}
		
		public function load(url:String):void
		{	
			unload();
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
			loader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			//loader.contentLoaderInfo.addEventListener(Event.INIT, initHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			//loader.contentLoaderInfo.addEventListener(Event.OPEN, openHandler);
			//loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			loader.contentLoaderInfo.addEventListener(Event.UNLOAD, unloadHandler);	
			loader.load(new URLRequest(url));
		}
				
		private function completeHandler(event:Event):void {
			var w:int = loader.contentLoaderInfo.width;
			var h:int = loader.contentLoaderInfo.height;
			x = (stage.stageWidth - w)>>1;
			y = (stage.stageHeight - h)>>1;
			addChild(loader);
		}
		
		private function httpStatusHandler(event:HTTPStatusEvent):void {
			if(event.status > 400) error("HTTP status: " + event.status);
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void {
			error("IO error: " + event.errorID);
		}
		
		private function unloadHandler(event:Event):void {
			removeChildAt( getChildIndex(loader) );	
		}
		
		private function error(msg:String):void {
			if(Log.isError()){ Log.getLogger(Logger.DEFAULT_CATEGORY).error(msg); }
		}
	}
}