package com.numeda.MIDIANE
{
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.external.ExtensionContext;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import org.osflash.signals.Signal;
	
	public class MIDIANE extends EventDispatcher
	{
		private var _extContext:ExtensionContext;
		
		public var channels:Vector.<MIDIANEChannel> = new Vector.<MIDIANEChannel>();
		
		public var onHihat:Signal = new Signal();
		public var onBeat:Signal = new Signal();
		public var onSnare:Signal = new Signal();
		public var onMeasure:Signal = new Signal();
		public var onDoubleMeasure:Signal = new Signal();
		public var onHalfPhrase:Signal = new Signal();
		public var onPhrase:Signal = new Signal();
		public var onMegaPhrase:Signal = new Signal();
		
		private var _t:int;
		private var _dict:Dictionary = new Dictionary(false);
		
		public function MIDIANE()
		{
			super();
			
			_extContext = ExtensionContext.createExtensionContext("com.numeda.MIDIANE", "" );
			if ( !_extContext ) {
				throw new Error( "Not supported on this target platform." );
			}
			
			_dict[_extContext] = true;
			function test() {
				
			}
			setTimeout(test, 1000);
			_extContext.addEventListener(StatusEvent.STATUS, handleStatus);
			_t = getTimer();
			
			for (var i:int=0; i<16; i++) {
				channels.push(new MIDIANEChannel());
			}
		}
		
		private function handleStatus (event:StatusEvent) : void
		{
			const levelArray:Array = event.level.split("/");
			const channel:int = levelArray[0];
			const  value:int =  levelArray[1];
			const rest:int = levelArray[2];
			const code:String = event.code;

			// handle status.
			if (code=="NOTEON") {
					//trackIndex:uint, pitch:uint, duration:uint, velocity:uint)
					channels[channel].onNoteOnInternal(value, 1, rest);
			
			} else if (code== "NOTEOFF") {
					channels[channel].onNoteOffInternal(value);
			
			} else if (code=="KEYPRESSURE") {

			} else if (code=="CC") {
					channels[channel].onCC.dispatch(value, rest);

			} else if (code=="PROGRAMCHANGE") {
			
			} else if (code=="CHANNELPRESSURE") {
			
				
			} else if (code=="PITCHBEND") {
				
			} else if (code=="MEGAPHRASE") {
					onMegaPhrase.dispatch();
					
			} else if (code=="PHRASE") {
					onPhrase.dispatch();
			
			} else if (code=="HALFPHRASE") {
					onHalfPhrase.dispatch();

			} else if (code=="DOUBLEMEASURE") {
					onDoubleMeasure.dispatch();

			} else if (code=="MEASURE") {
					onMeasure.dispatch();

			} else if (code=="SNARE") {
					onSnare.dispatch();

			} else if (code=="BEAT") {
					onBeat.dispatch();
					
			} else if (code=="HIHAT") {
					onHihat.dispatch();
					
			} else if (code=="QUARTERNOTE") {
					//NOTE THIS DOESNT EXIST YET IN THE NATIVE CODE. SORRY.
			
			} else if (code=="LOG") {
					trace("Log: " + event.level);
			}
		}
		
		public function isSupported() : Boolean
		{
			return _extContext.call("isSupported");
		}
		
		public function addMIDIDeviceListener(device:String) : void
		{
			if (!_extContext.call("addMIDIDeviceListener", device)) {
				throw new Error ("MIDIANE Error:  Attempting to set a MIDI Device that does not exist. Use getMIDIDeviceList() to find out the available ones (Device: "+ device);
			}
		}
		
		public function getMIDIDevice() : String
		{
			return _extContext.call("getMIDIDevice") as String;
		}
		
		public function getMIDIDeviceList() : Array
		{
			return _extContext.call("getMIDIDeviceList") as Array;
		}
		
		public function dispose() : void
		{
			_extContext.dispose();
		}
	}
}