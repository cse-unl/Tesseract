package com.maccherone.mpv
{
	public class ThresholdedMapMatrix extends ReadOnlyMapMatrix
	{
		private var _threshold:Number;
		
		public function ThresholdedMapMatrix(base:MapMatrix, threshold:Number)
		{
			super(base);
			_threshold = threshold;
		}
		
		public override function getValue(i:String, j:String):Number {
			var tempValue:Number = _base.getValue(i, j);
			if (_threshold >= 0) {
				if (tempValue >= _threshold) {
					return tempValue;
				} else {
					return 0;
				}
			} else {
				if (tempValue <= -_threshold) {
					return tempValue;
				} else {
					return 0;
				}
			}
		}
	}
}