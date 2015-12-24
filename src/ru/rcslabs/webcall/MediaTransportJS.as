package ru.rcslabs.webcall
{
	import flash.external.ExternalInterface;
	
	import mx.logging.Log;
	
	import ru.rcslabs.net.NetStreamer;
	import ru.rcslabs.utils.Logger;
	import ru.rcslabs.utils.monitor.IMonitorDelegate;
	import ru.rcslabs.utils.monitor.MicMonitor;
	import ru.rcslabs.webcall.events.HardwareEvent;
	import ru.rcslabs.webcall.events.MediaTransportEvent;

	public class MediaTransportJS extends MediaTransport implements IMonitorDelegate
	{				
		private var ctx:MEDIA2JS;
		
		public function MediaTransportJS(context:MEDIA2JS)
		{
			super();	
			this.ctx = context;
			if(ExternalInterface.available){
				registerCallbacks();
			}
		}
		
		override public function onPublish(streamer:NetStreamer):void{
			super.onPublish(streamer);
			if(streamer.hasVideoStream){
				ctx.pubCont.visible = true;
			}
		}
		
		override public function onSubscribe(streamer:NetStreamer):void{
			super.onSubscribe(streamer);
			if(streamer.hasVideoStream){
				ctx.subCont.visible = true;
			}			
		}
		
		private function registerCallbacks():void
		{
			ExternalInterface.addCallback("publish", publish);
			ExternalInterface.addCallback("unpublish", unpublish);
			ExternalInterface.addCallback("subscribe", subscribe);
			ExternalInterface.addCallback("unsubscribe", unsubscribe);			
			ExternalInterface.addCallback("muteMicrophone", __muteMicrophone);
			ExternalInterface.addCallback("microphoneVolume", __microphoneVolume);
			ExternalInterface.addCallback("muteSound", __muteSound);
			ExternalInterface.addCallback("soundVolume", __soundVolume);
			ExternalInterface.addCallback("checkHardware", __getHardwareState);
			ExternalInterface.addCallback("getVersion", getVersion);
			
			addEventListener(HardwareEvent.HARDWARE_STATE, hwHandler);
			addEventListener(HardwareEvent.MIC_MUTE_CHANGED, hwHandler);
			addEventListener(HardwareEvent.MIC_VOLUME_CHANGED, hwHandler);
			addEventListener(HardwareEvent.SOUND_MUTE_CHANGED, hwHandler);
			addEventListener(HardwareEvent.SOUND_VOLUME_CHANGED, hwHandler);
			
			addEventListener(MediaTransportEvent.PUBLISHED, mHandler);
			addEventListener(MediaTransportEvent.UNPUBLISHED, mHandler);
			addEventListener(MediaTransportEvent.PUBLISH_FAILED, mHandler);
			addEventListener(MediaTransportEvent.SUBSCRIBED, mHandler);
			addEventListener(MediaTransportEvent.UNSUBSCRIBED, mHandler);
			addEventListener(MediaTransportEvent.SUBSCRIBE_FAILED, mHandler);		
		}	
		
		private function getVersion():String
		{
			return WEBCALL::APP_VERSION;
		}
		
		private function __getHardwareState():void
		{			
			ctx.hw.run();
			dispatchHardwareStateEvent(false);
			// super.getHardwareState(ctx.stage);			
		}
		
		private function __muteMicrophone(value:Boolean):void{
			super.muteMicrophone = value;
			Log.getLogger(Logger.DEFAULT_CATEGORY).debug("muteMicrophone:"+value);
		}
	
		private function __microphoneVolume(value:Number):void{
			super.microphoneVolume = value;
			Log.getLogger(Logger.DEFAULT_CATEGORY).debug("microphoneVolume:"+value);
		}
		
		private function __muteSound(value:Boolean):void{
			super.muteSound = value;
			Log.getLogger(Logger.DEFAULT_CATEGORY).debug("muteSound:"+value);
		}

		private function __soundVolume(value:Number):void{
			super.soundVolume = value;
			Log.getLogger(Logger.DEFAULT_CATEGORY).debug("soundVolume:"+value);
		}
		
		public function onMonitorStateChanged(value:int):void{
			// see states in MicMonitor
			// CHECK_MIC_STATE:int = 0;
			//trace(value);
			switch(value)
			{	
				case MicMonitor.OK_LEVEL_STATE: 	
					dispatchHardwareStateEvent(true);			
					break;
			}
		}
		
		private function dispatchHardwareStateEvent(isUserDefined:Boolean):void
		{
			var event:HardwareEvent = new HardwareEvent(HardwareEvent.HARDWARE_STATE);
			event.data = {microphone:{}, camera:{}, userDefined:isUserDefined};
			event.data.microphone.name = ctx.hw.micName;
			event.data.microphone.state = ctx.hw.micState;
			event.data.camera.name = (camera ? camera.name : null);
			event.data.camera.state = (!camera ? "absent" : (camera.muted ? "disabled" : "enabled"));
			dispatchEvent(event);
		}
		
		private function mHandler(e:MediaTransportEvent):void{
			ExternalInterface.call(ctx.CALLBACK, e.toObject());	
		}
		
		private function hwHandler(e:HardwareEvent):void
		{
			ExternalInterface.call(ctx.CALLBACK, e.toObject());	
		}
	}
}