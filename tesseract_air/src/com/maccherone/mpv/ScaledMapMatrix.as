package com.maccherone.mpv
{
	public class ScaledMapMatrix extends ReadOnlyMapMatrix
	{
		private var _multiplier:Number;
		
		public function ScaledMapMatrix(base:MapMatrix, multiplier:Number)
		{
			super(base);
			_multiplier = multiplier;
		}
		
		public override function getValue(i:String, j:String):Number {
			return _base.getValue(i, j) * _multiplier;
		}
		
	}
}