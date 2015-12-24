package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.system.Security;
	
	import mx.logging.Log;
	
	import ru.rcslabs.components.HardwareTest;
	import ru.rcslabs.components.VideoContainer;
	import ru.rcslabs.config.Config;
	import ru.rcslabs.utils.DragHelper;
	import ru.rcslabs.utils.Logger;
	import ru.rcslabs.webcall.*;
	import ru.rcslabs.webcall.events.MediaTransportEvent;
	import ru.rcslabs.webcall.vo.ClientInfoVO;
	
	[SWF(width="220", height="140", frameRate="30")]
	public class MEDIA2JS extends Sprite
	{
		public var hw:HardwareTest;
		
		public var subCont:VideoContainer;
		
		public var pubCont:VideoContainer;
		
		private var config:Config;
		
		private var mt:MediaTransportJS;
				
		private var dm:DragHelper;
		
		private var dialSoundChannel:SoundChannel;
		
		public var CALLBACK:String = null;

		public function MEDIA2JS()
		{
			super();
			Security.allowDomain("*");
			Security.allowInsecureDomain("*");						
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			config = new AppConfig();
			
			if(ExternalInterface.available)
			{
				config.initFromFlashVars(loaderInfo.parameters);				
				
				Logger.init(config.logLevel);

				if(undefined == loaderInfo.parameters['cbMedia']){
					Log.getLogger(Logger.DEFAULT_CATEGORY).error("Callback 'cbMedia' undefined");	
					throw new Error("You have to define 'cbMedia' on flashVars");	
				}else{
					CALLBACK = loaderInfo.parameters['cbMedia'];
				}

				if(undefined == loaderInfo.parameters['cbReady']){
					Log.getLogger(Logger.DEFAULT_CATEGORY).error("Callback 'cbReady' undefined");	
					throw new Error("You have to define 'cbReady' on flashVars");	
				}

				if(Log.isDebug()){
					var info:ClientInfoVO = ClientInfoVO.createInfo();
					Log.getLogger(Logger.DEFAULT_CATEGORY).debug(loaderInfo.url);
					Log.getLogger(Logger.DEFAULT_CATEGORY).debug(info.pageUrl);				
					Log.getLogger(Logger.DEFAULT_CATEGORY).debug(info.userAgent);
					Log.getLogger(Logger.DEFAULT_CATEGORY).debug("MEDIA2JS " + WEBCALL::APP_VERSION);
					Log.getLogger(Logger.DEFAULT_CATEGORY).debug(config.toString());
				}

				//dm = new DragHelper();
				
				ExternalInterface.marshallExceptions = true;
				
				ExternalInterface.addCallback("muteSubscriber", muteSubscriber);
				ExternalInterface.addCallback("playRBT", playDialingSound);
				ExternalInterface.addCallback("stopRBT", stopDialingSound);
				ExternalInterface.addCallback("playDtmf", playDtmf);
			}

			mt = new MediaTransportJS(this);								
			mt.init(config);
			
			mt.addEventListener(MediaTransportEvent.PUBLISHED, pubHandler);
			mt.addEventListener(MediaTransportEvent.UNPUBLISHED, unpubHandler);
			mt.addEventListener(MediaTransportEvent.SUBSCRIBED, subHandler);
			mt.addEventListener(MediaTransportEvent.UNSUBSCRIBED, unsubHandler);
			
			subCont = addChild(new VideoContainer) as VideoContainer;
			subCont.setSizeAndPositionAsRectangle(config.subscriberRect);
			subCont.visible = false;
			
			pubCont = addChild(new VideoContainer) as VideoContainer;
			pubCont.setSizeAndPositionAsRectangle(config.publisherRect);
			pubCont.visible = false;
			
			hw = addChild(new HardwareTest(mt)) as HardwareTest;
			
			stage.addEventListener(Event.RESIZE, resizeHandler);
			resizeHandler();
			
			// test case
			if(!ExternalInterface.available){
				hw.run();
			}else{
				ExternalInterface.call(loaderInfo.parameters.cbReady);
			}
		}
		
		private function resizeHandler(event:Event=null):void
		{
//			trace(stage.stageWidth, stage.stageHeight);
			if(subCont){subCont.setSizeAndPositionAsRectangle(new Rectangle(0,0,stage.stageWidth,stage.stageHeight));} 
			if(pubCont){pubCont.x = pubCont.y = 0; } 
		}
		
		private function playDialingSound():void
		{
			if(null != dialSoundChannel){ return; }
			var s:Sound = SoundManager.createSound(SoundManager.SND_DIAL);
			dialSoundChannel = s.play(0, 30);		
		}
		
		private function stopDialingSound():void
		{
			if(null == dialSoundChannel){ return; }
			dialSoundChannel.stop();
			dialSoundChannel = null;
		}
		
		private function playDtmf(char:String):void
		{
			SoundManager.play(char, 100); 
		}

		private function pubHandler(e:MediaTransportEvent):void
		{
			pubCont.visible = (null != mt.publisherVideo);
			pubCont.video = mt.publisherVideo;	
		}
		
		private function subHandler(e:MediaTransportEvent):void
		{
			subCont.visible = (null != mt.subscriberVideo);
			subCont.video = mt.subscriberVideo;
		}

		private function unpubHandler(e:MediaTransportEvent):void
		{
			pubCont.video = null;
			pubCont.visible = false;
		}

		private function unsubHandler(e:MediaTransportEvent):void
		{
			subCont.video = null;
			subCont.visible = false;
		}

		private function muteSubscriber(value:Boolean):void
		{
			mt.voiceSubscriber.volume = (value ? 0 : 1);	
		}
	}
}