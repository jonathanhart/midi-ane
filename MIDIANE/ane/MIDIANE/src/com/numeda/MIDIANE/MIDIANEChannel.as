package com.numeda.MIDIANE
{
	import flash.utils.ByteArray;
	
	import org.osflash.signals.Signal;

	public class MIDIANEChannel
	{
	
		private var _activeNotes:Array = new Array();
	
		// Signal params are: channel, level
		public var onNote:Signal = new Signal(uint, uint, uint, Signal);
		public var onCC:Signal = new Signal(uint, uint);
		public var onPitchBend:Signal = new Signal(uint, uint, uint, uint);
		public var onMeta:Signal = new Signal(uint, String, uint, ByteArray);

		public function MIDIANEChannel()
		{
		
		}
		
		public function onNoteOnInternal(pitch:uint, duration:uint, rest:uint) : void
		{
			if (!_activeNotes[pitch]) {
				_activeNotes[pitch] = new Signal();
			}
			onNote.dispatch(pitch, duration, rest, _activeNotes[pitch]);
		}

		public function onNoteOffInternal(pitch:int) : void
		{
			pitch -= 32;
			if(_activeNotes[pitch] != null) {
				_activeNotes[pitch].dispatch();
				_activeNotes[pitch].removeAll();
				_activeNotes[pitch] = null;
			}
		}
	}
}