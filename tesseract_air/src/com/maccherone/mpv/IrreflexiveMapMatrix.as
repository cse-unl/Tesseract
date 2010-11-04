package com.maccherone.mpv
{
	public class IrreflexiveMapMatrix extends ReadOnlyMapMatrix
	{
		public function IrreflexiveMapMatrix(base:MapMatrix)
		{
			super(base);
		}

		public override function getValue(i:String, j:String):Number {
			if (i == j) {
				return 0;
			} else {
				return _base.getValue(i, j);
			}
		}
	}
}

