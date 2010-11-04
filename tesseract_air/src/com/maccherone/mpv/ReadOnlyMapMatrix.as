package com.maccherone.mpv
{
	/**
	* This class is essentially a read-only front-end for the base MapMatrix.
	* It is intended to be used in formulas where you only need to read.
	* It is also used as the base class for other read-only matrixes
	* that are derivatives/filters of some base.
	* If you try to call the methods that write, you should get an error.
	* You should also get an error if you try to access the data field.
	*
	* @author   Larry Maccherone
	*/
	public class ReadOnlyMapMatrix extends MapMatrix
	{
		protected var _base:MapMatrix;
		
		public function ReadOnlyMapMatrix(base:MapMatrix)
		{
			_base = base;
		}
		
		public override function getValue(i:String, j:String):Number {
			return _base.getValue(i, j);
		}
		
		public override function setValue(i:String, j:String, value:Number,
				uniqueIValue:Object=null, uniqueJValue:Object=null):void {
			throw new Error("Can't write to ReadOnlyMapMatrix");
		}
		
		public override function getRow(i:String):Object {
			throw new Error("It's unsafe to access this from a ReadOnlyMapMatrix");
		}
		
		public override function increment(i:String, j:String,
				uniqueIValue:Object=null, uniqueJValue:Object=null):void {
			throw new Error("Can't write to ReadOnlyMapMatrix");
		}
		
		public override function plusEquals(i:String, j:String, value:Number,
				uniqueIValue:Object=null, uniqueJValue:Object=null):void {
			throw new Error("Can't write to ReadOnlyMapMatrix");
		}
			
		public override function get uniqueIs():Object {
			return _base.uniqueIs;
		}
		
		public override function set uniqueIs(value:Object):void {
			throw new Error("Can't write to ReadOnlyMapMatrix");
		}
		
		public override function get uniqueJs():Object {
			return _base.uniqueJs;
		}

		public override function set uniqueJs(value:Object):void {
			throw new Error("Can't write to ReadOnlyMapMatrix");
		}
		
	}
}