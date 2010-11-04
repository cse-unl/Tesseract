package com.maccherone.mpv
{
	import com.adobe.flex.extras.controls.springgraph.Graph;
	import com.adobe.flex.extras.controls.springgraph.Item;

	import flash.events.Event;
	import flash.events.MouseEvent;

	import mx.containers.Box;


	public class MPVNode extends Box
	{
		private var _data:Object = null; 
//		private var text:Label;
		private var mousedOver:Object;
		private var _parentGraph:Graph;
		private var dm:DataManipulator;
		public var type:String;
		private var neighborCount:int;
		private var neighbors:String;
		private var isPackage:Boolean;

		public function MPVNode(parentGraph:Graph, item:Item)
		{
			dm = DataManipulator.getInstance();
			super();
			if (parentGraph == null) {
				throw new Error("Constructor for MPVNode requires a valid parentGraph");
			}
			_parentGraph = parentGraph;

			if (item == null) throw new Error("item cannot be null when creating a new MPVNode");

			// check if it is package node
			this.isPackage = isPackageNode(item);

			this.width = 16;
			this.height = this.width;
			this.setStyle("backgroundColor", dm.nodeColor);
			this.setStyle("backgroundAlpha", 0.4);
			this.setStyle("cornerRadius", getCornerRadius());
			this.setStyle("borderStyle", "solid");
			this.setStyle("borderThickness", 0);

//			this.setStyle("paddingBottom", 1);
//			this.setStyle("paddingLeft", 3);
//			this.setStyle("paddingRight", 3);
//			this.setStyle("paddingTop", 1);

//			text = new Label();
//
//			text.setStyle("fontSize",  7);
//			text.setStyle("color", 0xffffff);
//			text.setStyle("textAlign", "center");
//			text.setStyle("backgroundColor", 0x0000ff);
//			
//			this.addChild(text);

			if (item != null) {  
				item.data["MPVNode"] = this;
				if (this._parentGraph == dm.dToDGraph){
					// set node tooltip in d-to-d graph according to the d-to-d mode
					if(dm.dToDMode == "communication"){
						this.neighborCount = dm.dToD.getCommunicationCount(item.data["id"]);
						this.neighbors = dm.dToD.getCommunicationNeighborsAsString((item.data["id"]), "name");
					}else if(dm.dToDMode == "coordinationRequirement"){
						this.neighborCount = dm.dToD.getRequirementCount(item.data["id"]);
						this.neighbors = dm.dToD.getRequirementNeighborsAsString((item.data["id"]), "name");
					}else{// congruence, show all links
						this.neighborCount = dm.dToD.getLinkCount(item.data["id"]);
						this.neighbors = dm.dToD.getNeighborsAsString((item.data["id"]), "name");
					}

					this.toolTip = dm.dToD.uniqueIs[item.data["id"]]["name"] + "\nneighbors count: " 
						+ this.neighborCount + neighbors;
					this.type = "developer";
				}
				else {
					// set node tooltip in f-to-f graph
					this.neighborCount = dm.pToP.getLinkCount(item.data["id"]);
					this.neighbors = dm.pToP.getNeighborsAsString((item.data["id"]), "file_name");
					var fileName:String = dm.pToP.uniqueIs[item.data["id"]]["file_name"];
					if(this.isPackage){
						var fileCount:int = dm.packToFileIDs(fileName).length;
						this.toolTip = fileName + "\nfiles count: " + fileCount + 
							"\nneighbors count: " + this.neighborCount + neighbors;
					} else {
						this.toolTip = fileName + "\nneighbors count: " + this.neighborCount + neighbors;
					}

					this.type = "file";
				}
			}

			this.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			// Note, we don't need to register click or doubleClick.  SpringGraph will automatically
			// call these (if the node has these functions) when a click or doubleClick occurs.
		}

		// set corner radius to display circle for file nodes, rectangle for package nodes
		public function getCornerRadius():Number {
			if(isPackage){
				return 0;
			}else{
				return this.width/2;
			}
		}

		// check if this node is package node or file node
		public function isPackageNode(item:Item):Boolean{
			if(dm.packages.indexOf(item.data["id"]) < 0){
				return false;
			}
			return true;
		}

		public function doubleClick():void {
			if (this._parentGraph == dm.dToDGraph) {
				if (! dm.application.isSelectedDeveloper(this._data["data"]["id"])) {
					click();
				}
			} else if (this._parentGraph == dm.fToFGraph) {
				if (dm.application.isSelectedPackage(this._data["data"]["id"])){
					// set display object to invisible to improve performance
					dm.application.setVisibility(false);

					// if the node double clicked is a package, explore and display 
					// the children nodes in it
					dm.packageNodeDoubleClick(this._data["data"]["id"]);

					// set display object to invisible to improve performance
					dm.application.setVisibility(true);

					// display the clear drill down button
					dm.application.clearDrillDownButton.visible = true;

					return;
				}else if (! dm.application.isSelectedFile(this._data["data"]["id"])) {
					click();
				}
					// TODO: Add for bugs here. Drill down.
			} else {
				throw("Unrecognized parent graph");
			}			

			dm.application.filterBySelected();
		}

		public function click():void {
			if (this._parentGraph == dm.dToDGraph) {
				dm.developerNodeClick(_data["data"]["id"]);
			} else if (this._parentGraph == dm.fToFGraph) {
				if(this.isPackage){
					dm.packageNodeClick(_data["data"]["id"]);
				}else if(!dm.isFToF){
					dm.fileNodeClick(dm.fileNameToId(_data["data"]["id"]));
				}else{
					dm.fileNodeClick(_data["data"]["id"]);
				}
					// TODO: Add for bugs here. Click but not sure if this is done here in MPVNode.
			} else {
				throw("Unrecognized parent graph");
			}
		}

		public function ctrlClick():void {
			if (this._parentGraph == dm.dToDGraph) {
				dm.developerNodeControlClick(_data["data"]["id"]);
			} else if (this._parentGraph == dm.fToFGraph) {
				if(this.isPackage){
					dm.packageNodeControlClick(_data["data"]["id"]);
				}else if(!dm.isFToF){
					dm.fileNodeControlClick(dm.fileNameToId(_data["data"]["id"]));
				}else{
					dm.fileNodeControlClick(_data["data"]["id"]);
				}
					// TODO: Add for bugs here. CtrlClick but not sureif this is done here in MPVNode.
			} else {
				throw("Unrecognized parent graph");
			}
		}

		public function shiftClick():void {
			// Do nothing, let the drag work
		}

		public function ctrlShiftClick():void {
			// For now, do nothing but may find a use for this later.
		}

//		public function getDragTogetherNodes():Array {
//			var selectedIDs:Object;
//			var selectedNodes:Array;
//			if (this._parentGraph == dm.dToDGraph) {
//				selectedNodes = dm.application.getSelectedDeveloperNodes();
//			} else if (this._parentGraph == dm.fToFGraph) {
////				selectedIDs = dm.application.getSelectedIDs(dm.application.fileList);
//			// TODO: Add for bugs here. Feature commented out for now
//			} else {
//				throw("Unrecognized parent graph");
//			}
//
//			return selectedNodes;
//		}

		public function onMouseOver(event:MouseEvent):void {
			var dm:DataManipulator = DataManipulator.getInstance();
			this.setStyle("backgroundAlpha", 1.0);
			mousedOver = _parentGraph.neighbors(_data["data"]["id"]);
			for (var i:String in mousedOver) {
				MPVNode(Item(_parentGraph.nodes[i]).data["MPVNode"]).setStyle("backgroundAlpha", 0.65);
			}
		}

		public function onMouseOut(event:MouseEvent):void {
			var dm:DataManipulator = DataManipulator.getInstance();
			this.setStyle("backgroundAlpha", 0.4);
			for (var i:String in mousedOver) {
				MPVNode(Item(_parentGraph.nodes[i]).data["MPVNode"]).setStyle("backgroundAlpha", 0.4);//right now only for d2D graph. Have to employ logic of prev function to choose from which graph node has been seclected and use that graph
			}
			mousedOver = {};
		}

		[Bindable("dataChange")]
		public override function get data(): Object {
			return _data;
		}

		public override function set data(d: Object): void {
			_data = d;
//			text.text = d["data"]["id"];  
			dispatchEvent(new Event("dataChange"));
		}
	}
}

