package com.maccherone.mpv
{
	import com.adobe.flex.extras.controls.springgraph.Graph;
	import com.adobe.flex.extras.controls.springgraph.IViewFactory;
	import com.adobe.flex.extras.controls.springgraph.Item;
	
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;

	public class MPVViewFactory implements IViewFactory
	{
		private var _parentGraph:Graph;
		
		public function MPVViewFactory()
		{
			
		}

		public function set parentGraph(value:Graph):void {
			_parentGraph = value;
		}
		
		public function getView(item:Item):UIComponent
		{
			if (_parentGraph == null) {
				throw new Error("parent Graph null");
			}
			var temp:MPVNode = new MPVNode(_parentGraph, item);
			return temp;
		}
		
	}
}