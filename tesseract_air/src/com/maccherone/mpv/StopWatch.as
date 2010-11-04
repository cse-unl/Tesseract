package com.maccherone.mpv
{
	public class StopWatch
	{
		private var _start:Number;
		
		public function StopWatch() {
			start();
		}
		
		public function start(message:String = "Start"):void {
			_start = (new Date()).time;
			trace(message);
		}
		
		public function interval(message:String = "Split"):void {
			var now:Number = (new Date()).time;
			trace(message + ":" + (now - _start).toString());
		}

	}
}