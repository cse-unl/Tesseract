package com.maccherone.mpv
{
	public class BinaryMapMatrix extends ReadOnlyMapMatrix
	{
		public function BinaryMapMatrix(base:MapMatrix)
		{
			super(base);
		}
		
		public override function getValue(i:String, j:String):Number {
			if (_base.getValue(i, j) != 0) {
				return 1;
			} else {
				return 0;
			}
		}
		
	}
}