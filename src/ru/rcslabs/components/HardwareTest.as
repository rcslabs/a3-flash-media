package ru.rcslabs.components
{
	import com.bit101.components.Meter;
	
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.media.Microphone;
	import flash.utils.setTimeout;
	
	import flashx.textLayout.formats.TextAlign;
	
	import ru.rcslabs.utils.monitor.IMicMonitorDelegate;
	import ru.rcslabs.utils.monitor.IMonitorDelegate;
	import ru.rcslabs.utils.monitor.MicMonitor;
	import ru.rcslabs.webcall.AppConfig;
	import ru.rcslabs.webcall.MediaTransport;
	
	public class HardwareTest extends Sprite implements IMicMonitorDelegate
	{		
		private var vu1:VUMeter;
		private var vu2:Meter;	
		private var state:int;
		private var monit:MicMonitor;
		public  var micName:String;
		public  var micState:String = "absent";
		private var delegate:IMonitorDelegate;
		private var mic:Microphone;

		// sprite size on testing hardware should be 220x140
		public function HardwareTest(delegate:IMonitorDelegate)
		{
			super();
			this.delegate = delegate;
			this.y = 10;
			
			vu1 = addChild(new VUMeter) as VUMeter;	
			vu1.x = 10; vu1.y = 110;
			vu1.scaleX = (2/2.8); // vu meter width = 280 px, resize it to 200
			
			vu2 = new Meter(this, 10, 0);
			vu2.maximum = 100;
			hideMeter();
		}
		
		public function run():void
		{
			mic = Microphone.getMicrophone();
			if(mic) micName = mic.name;
			
			monit = new MicMonitor();
			monit.init();
			monit.setMonitorDelegate(this);
			monit.setMicrophone(mic);
			monit.setStage(stage);
			monit.check();		
		}
		
		private function showMeter():void {
			vu2.value   = vu1.level = 0;
			vu2.visible = vu1.visible = true;	
		}
		
		private function hideMeter():void {
			vu2.visible = vu1.visible = false;
		}
		
		public function onMicIndexChanged(index:int, name:String):void {
			micName = name;	
		}
		
		public function onMicLevel(value:int):void {
			vu2.value = vu1.level = value;
		}
		
		public function onMonitorStateChanged(value:int):void
		{
			state = value;
			//trace(state);
			hideMeter();
			
			micState = (!mic ? "absent" : (mic.muted ? "disabled" : "enabled"));
			
			switch(value)
			{
				case MicMonitor.CHECK_MIC_STATE: 
					delegate.onMonitorStateChanged(value);	
					break;
				
				case MicMonitor.MIC_DISABLED_STATE: 
					monit.check();
					break;
				
				case MicMonitor.MIC_ABSENT_STATE:
					monit.check();
					break;
				
				case MicMonitor.CHECK_LEVEL_STATE: 	
					// quick fix
					// if swf was configure with parameter 'checkMicVolume=false'
					// skip this and next state 
					if(AppConfig(MediaTransport(delegate).config).checkMicVolume){
						delegate.onMonitorStateChanged(value);
						showMeter();
					} else { 
						// Thanks Jenya!
						setTimeout(function():void{
							onMonitorStateChanged(MicMonitor.OK_LEVEL_STATE);
						}, 33);
					}
					break;	
				
				case MicMonitor.NO_LEVEL_STATE: 	
					monit.check();
					break;						

				case MicMonitor.OK_LEVEL_STATE: 	
					monit.dispose();
					delegate.onMonitorStateChanged(value);			
					break;
			}
		}		
	}
}