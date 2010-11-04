package com.maccherone.mpv
{
	import com.adobe.flex.extras.controls.springgraph.Graph;
	import com.adobe.flex.extras.controls.springgraph.IEdgeRenderer;
	
	import flash.display.Graphics;
	
	import mx.core.UIComponent;


	public class MPVEdgeRenderer implements IEdgeRenderer
	{
		private var _colorMatrix:MapMatrix;
		private var _thicknessMatrix:MapMatrix;
		private var _thicknessFunction:Function = _defaultThicknessFunction;
		private var _maxValueInThicknessMatrix:Number;
		private var _maxThickness:Number = 10;
		private var _logN:Number;
		private var _colorMap:Object;
		private var _defaultColor:uint = 0xff0000; // red
		static private var lineThickness:Number = 1;
		static private var lineAlpha:Number = 0.5;
		
		public function MPVEdgeRenderer()
		{
		}
		
		public function set colorMatrix(value:MapMatrix):void {
			_colorMatrix = value;
		}
		
		public function set thicknessMatrix(value:MapMatrix):void {
			_thicknessMatrix = value;
			_maxValueInThicknessMatrix = _thicknessMatrix.max();
			_recalcLogN();
		}
		
		public function set maxThickness(value:Number):void {
			_maxThickness = value;
			_recalcLogN();
		}

		private function _recalcLogN():void {
			_logN = Math.pow(_maxValueInThicknessMatrix, 1.0/(_maxThickness-1.0));
		}
		
		public function set thicknessFunction(value:Function):void {
			_thicknessFunction = value;
		}
		
		private function _defaultThicknessFunction(value:Number):Number {
			var temp:Number = Math.max(value, 1.0);
			return Math.pow(temp, 1.0/_logN) + 1.0;
		}
		
		public function set colorMap(value:Object):void {
			_colorMap = value;
		}
		
		public function set defaultColor(value:uint):void {
			_defaultColor = value;
		}

		public function draw(g:Graphics, fromView:UIComponent, toView:UIComponent, fromX:int, fromY:int, toX:int, toY:int, graph:Graph):Boolean
		{
			var i:String = fromView["data"]["id"];
			var j:String = toView["data"]["id"];
			var colorValue:Number = _colorMatrix.getValue(i, j);
			lineThickness = _thicknessFunction(_thicknessMatrix.getValue(i, j));
			var color:uint = _defaultColor;
			if (_colorMap.hasOwnProperty(colorValue.toString())) {
				color = _colorMap[colorValue.toString()];
			}
//			lineThickness = colorValue;
			g.lineStyle(lineThickness, color, lineAlpha);
			g.moveTo(fromX, fromY);
			g.lineTo(toX, toY);
			return true;
		}
		
	}
}