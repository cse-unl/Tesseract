package com.maccherone.mpv
{

	public class TransposedMapMatrix extends ReadOnlyMapMatrix
	{		
		public function TransposedMapMatrix(base:MapMatrix)
		{
			super(base);
		}
		
		public override function getValue(i:String, j:String):Number {
			return _base.getValue(j, i);
		}
		
		public override function get uniqueIs():Object {
			return _base.uniqueJs;
		}
		
		public override function get uniqueJs():Object {
			return _base.uniqueIs;
		}
		
	}
}