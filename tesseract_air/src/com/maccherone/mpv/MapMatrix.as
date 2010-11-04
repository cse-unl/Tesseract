package com.maccherone.mpv {

	import com.adobe.flex.extras.controls.springgraph.Graph;
	import com.adobe.flex.extras.controls.springgraph.Item;

	import flash.utils.describeType;

	public class MapMatrix
	{
		private var _data:Object;
		private var _uniqueIs:Object;
		private var _uniqueJs:Object;

		// cell values for defferent communications
		private static const EXTRA:Number = 1;
		private static const GAP:Number = 2;
		private static const MATCH:Number = 3;

		public function MapMatrix()
		{
			_data = {};
			_uniqueIs = {};
			_uniqueJs = {};
		}

		public static function test():void {
			var mm1:MapMatrix = new MapMatrix();
			var mm2:MapMatrix = new MapMatrix();

			// i and j values must be unique
			mm1.plusEquals("1", "1", 3);
			mm1.plusEquals("1", "1", 4);
			mm1.setValue("1", "jack", 0);
			mm1.setValue("1", "3", 2);
			mm1.setValue("2", "1", -1);
			mm1.setValue("2", "jack", 3);
			mm1.setValue("2", "3", 1);
			mm1.setValue("3", "1", 2);
			mm1.setValue("3", "jack", 1);
			mm1.setValue("3", "3", 4);

			// i and j can be numbers.  MapMatrix will convert to strings before using as a key
			mm2.setValue("1", "1", 3);
			mm2.setValue("1", "2", 1);
			mm2.setValue("jack", "1", 2);
			mm2.setValue("jack", "2", 1);
			mm2.setValue("3", "1", 1);
			mm2.setValue("3", "2", 0);

			trace("mm1\n" + mm1);
			trace("mm2\n" + mm2);

//			// i and j values must be unique
//			mm1.setValue("1", "1", 1);
//			mm1.setValue("1", "jack", 0);
//			mm1.setValue("1", "3", 2);
//			mm1.setValue("2", "1", -1);
//			mm1.setValue("2", "jack", 3);
//			mm1.setValue("2", "3", 1);
//			mm1.setValue("3", "1", 2);
//			mm1.setValue("3", "jack", 1);
//			mm1.setValue("3", "3", 4);

//       		// i and j can be numbers.  MapMatrix will convert to strings before using as a key
//       		mm2.set(1, 1, 3);
//        	mm2.set(1, 2, 1);
//       		mm2.set("jack", 1, 2);
//       		mm2.set("jack", 2, 1);
//       		mm2.set(3, 1, 1);
//       		mm2.set(3, 2, 0);
//        	
//        	trace("mm1\n" + mm1);
//        	trace("mm2\n" + mm2);
//        	trace("mm1 x mm2\n" + mm1.times(mm2));
//        	trace("mm1 x mm2.thresholded at 1\n" + mm1.times(mm2.thresholded(1)));
//        	trace("mm1 transposed\n" + mm1.transposed);
//        	trace("mm1 binary\n" + mm1.binary);
//        	trace("mm1 threholded at 3\n" + mm1.thresholded(3));
//        	trace("mm1 scaled by 10\n" + mm1.scaled(10));
//        	trace("mm1 + (mm2 transposed)\n" + mm1.binary.plus(mm2.transposed));
		}



		public function populateGraph(graph:Graph, showOrphans:Boolean=false, valuePredicate:Function=null, 
			acceptableIDs:Object=null):void {  // TODO: Maybe add itemPredicate for filtering on values in of uniqueIs
			var tempItem:Item;
			var tempValue:Number;
			var filteredIs:Object;
			// Filtering Is by itemPredicate
			if (acceptableIDs == null) {
				filteredIs = this.uniqueIs;
			} else {
				filteredIs = {};
				for (var i:String in this.uniqueIs) {
					if (acceptableIDs.hasOwnProperty(i)) {
						filteredIs[i] = this.uniqueIs[i];
					}
				}
			}
			// Adding items (nodes)
			for (i in filteredIs) {
				if (showOrphans || this.getReflexiveLinkCount(i) > 0) { // TODO: This filtering for orphan nodes is untested
					tempItem = new Item(i);
					tempItem.data = {"id":i}; 
					this.uniqueIs[i]["item"] = tempItem;
					graph.add(tempItem);
				}
			}
			// Adding links (edges)
			for (i in filteredIs) {
				if (showOrphans || this.getLinkCount(i) > 0) {
					for (var j:String in filteredIs) {
						if (i != j) {
							tempValue = this.getValue(i, j);
							if (((valuePredicate == null) && (tempValue != 0)) || 
								(valuePredicate != null) && valuePredicate(tempValue)) {
								graph.link(this.uniqueIs[i].item, this.uniqueIs[j].item);
							}
						}
					}
				}
			}
		}

		public static function fromCollection(source:*, iField:String, jField:String, 
			uniqueIFunction:Function=null, uniqueJFunction:Function=null, 
			predicate:Function = null):MapMatrix {
			var temp:MapMatrix = new MapMatrix();
			var uniqueIValue:Object;
			var uniqueJValue:Object;
			for each (var row:Object in source) {
				if (predicate == null || predicate(row)){
					if (uniqueIFunction == null) {
						uniqueIValue = null;
					} else {
						uniqueIValue = uniqueIFunction(row);
					}
					if (uniqueJFunction == null) {
						uniqueJValue = null;
					} else {
						uniqueJValue = uniqueJFunction(row);
					}					
					temp.increment(row[iField], row[jField], uniqueIValue, uniqueJValue);
				}
			}
			return temp;
		}

		public static function clusterByI(source:*, iField:String, jField:String, 
			uniqueIFunction:Function, uniqueJFunction:Function, predicate:Function = null):MapMatrix {
			var tempIToJ:MapMatrix = fromCollection(source, iField, jField, uniqueIFunction, uniqueJFunction, predicate);
			return tempIToJ.getJCrossReference();
		}

		protected function getJCrossReference():MapMatrix {
			var temp:MapMatrix = new MapMatrix();
			for each (var row:Object in _data) {
				for (var j1:String in row) {
					for (var j2:String in row) {
						temp.increment(j1, j2, _uniqueJs[j1], _uniqueJs[j2]); // This is not a bug. It is correct to pull both unique values from _uniqueJs.
					}
				}
			}
			return temp;
		}

		public function getRow(i:String):Object {
			return _data[i];
		}

		public function getExpandedRow(i:String):Object {
			var tempExpandedRow:Object = {};
			for (var j:String in uniqueJs) {
				tempExpandedRow[j] = this.getValue(i, j);
			}
			return tempExpandedRow;
		}

		public function getColumn(j:String):Object {
			var temp:Object = {}; 
			var tempValue:Number;
			for (var i:String in uniqueIs) {
				tempValue = getValue(i, j);
				if (! (tempValue == 0)){
					temp[i] = tempValue;
				}
			}
			return temp;
		}

		public function getExpandedColumn(j:String):Object {
			var tempColumn:Object = {}; 
			for (var i:String in uniqueIs) {
				tempColumn[i] = getValue(i, j);
			}
			return tempColumn;			
		}

		// get total count of nodes linked to a specific node
		public function getLinkCount(i:String):int {
			var temp:int = 0;
			for (var j:String in this.uniqueJs) {
				if ((i != j) && (this.getValue(i, j) > 0)) {
					temp++;
				}
			}
			return temp;
		}

		// get total count of nodes linked to a specific node
		public function getReflexiveLinkCount(i:String):int {
			var temp:int = 0;
			for (var j:String in this.uniqueJs) {
				if (this.getValue(i, j) > 0) {
					temp++;
				}
			}
			return temp;
		}

		/* get total count of nodes linked to a specific developer in coordination requirement mode,
		   used in d-to-d graph
		 */
		public function getRequirementCount(i:String):int {
			var temp:int = 0;
			for (var j:String in this.uniqueJs) {
				// if the link is a match or gap communication, count the linked node as a neighbor 
				if ((i != j) && (this.getValue(i, j) == MATCH || this.getValue(i, j) == GAP)) {
					temp++;
				}
			}
			return temp;
		}

		/* get total count of nodes linked to a specific developer in communication mode,
		   used in d-to-d graph
		 */		
		public function getCommunicationCount(i:String):int {
			var temp:int = 0;
			for (var j:String in this.uniqueJs) {
				// if the link is a match or extra communication, count the linked node as a neighbor 
				if ((i != j) && (this.getValue(i, j) == MATCH || this.getValue(i, j) == EXTRA)) {
					temp++;
				}
			}
			return temp;
		}

		/* public function getNeighbors(i:String):Array {
		   var temp:Array =[] ;
		   for (var j:String in this.uniqueJs) {
		   if ((i != j) && (this.getValue(i, j) > 0)) {
		   temp.push(j);
		   }
		   }
		   return temp;
		 } */

		/* get neighbors as string, used in both d-to-d graph and f-to-f graph
		 */
		public function getNeighborsAsString(i:String, valueName:String):String {
			var temp:String = "\nneighbors:";
			for (var j:String in this.uniqueJs) {
				// if the cell value is positive, add corresponding node to neighbors
				if ((i != j) && (this.getValue(i, j) > 0)) {
					temp += "\n\t" + this.uniqueJs[j][valueName];
				}
			}
			return temp;
		}

		/* get the string representation of the neighbor of a specific developer in communication mode,
		   used in d-to-d graph
		 */	
		public function getCommunicationNeighborsAsString(i:String, valueName:String):String {
			var temp:String = "\nneighbors:";
			for (var j:String in this.uniqueJs) {
				// if the link is a match or extra communication, count the linked node as a neighbor 
				if ((i != j) && (this.getValue(i, j) == MATCH || this.getValue(i, j) == EXTRA)) {
					temp += "\n\t" + this.uniqueJs[j][valueName];
				}
			}
			return temp;
		}

		/* get the string representation of the neighbor of a specific developer in coordination requirement mode,
		   used in d-to-d graph
		 */	
		public function getRequirementNeighborsAsString(i:String, valueName:String):String {
			var temp:String = "\nneighbors:";
			for (var j:String in this.uniqueJs) {
				// if the link is a match or gap communication, count the linked node as a neighbor 
				if ((i != j) && (this.getValue(i, j) == MATCH || this.getValue(i, j) == GAP)) {
					temp += "\n\t" + this.uniqueJs[j][valueName];
				}
			}
			return temp;
		}

		private static function nullFunction(row:Object):Object {
			return null;
		}

		// TODO: This doesn't work.  Stopped and went to sleep.
		public static function getDistribution(source:*, iField:String, jField:String,
			iFunction:Function, 
			predicate:Function = null):Array {
			var tempIToJ:MapMatrix = fromCollection(source, iField, jField, 
				nullFunction, nullFunction, predicate);
			var temp:Array = [];
			var tempObject:Object;
			for (var i:String in tempIToJ.uniqueIs) {
				tempObject = {};
				trace(iFunction(i));
				tempObject[iField] = iFunction(i);
				tempObject["count"] = tempIToJ.getLinkCount(i);
				trace(tempObject.count);
				temp.push(tempObject);
				trace("adding" + tempObject);
			}
			return temp;
		}

		public function setValue(i:String, j:String, value:Number, 
			uniqueIValue:Object=null, uniqueJValue:Object=null):void {
			if (uniqueIValue == null) {
				if (!(_uniqueIs.hasOwnProperty(i))) {
					_uniqueIs[i] = true;
				}
			} else {
				_uniqueIs[i] = uniqueIValue;
			}
			if (uniqueJValue == null) {
				if (!(_uniqueJs.hasOwnProperty(j))) {
					_uniqueJs[j] = true;
				}
			} else {
				_uniqueJs[j] = uniqueJValue;
			}
//			if (value==0) { // TODO: If a zero is sent in, it should really delete the cell
//				return;
//			}
			if (!_data.hasOwnProperty(i)) {
				_data[i] = {};
			}
			_data[i][j] = value;
		}

		public function getValue(i:String, j:String):Number {
			if (_data.hasOwnProperty(i)) {
				if (_data[i].hasOwnProperty(j)) {
					return _data[i][j];
				} else {
					return 0;
				}
			} else {
				return 0;
			}
		}

		// add entry to matrix if the entry doesn't exist
		// increase cell value if the entry exist
		public function plusEquals(i:String, j:String, value:Number,
			uniqueIValue:Object=null, uniqueJValue:Object=null):void {
			/* var valueToSet:Number;
			   // keep value to set as 0 if i and j are same
			   if(i == j){
			   valueToSet = 0;
			   }else{
			   valueToSet = getValue(i, j) + value;
			   }
			 setValue(i, j, valueToSet, uniqueIValue, uniqueJValue); */
			setValue(i, j, getValue(i, j) + value, uniqueIValue, uniqueJValue);
		}

		public function increment(i:String, j:String, 
			uniqueIValue:Object=null, uniqueJValue:Object=null):void {
			plusEquals(i, j, 1, uniqueIValue, uniqueJValue);
		}

		// This function is designed to work when the j's from the first matrix
		// perfectly coorespond with the i's from the second.
		// If this is not the case, it will throw an error.
		// However, if there are items in the i's from the second that are not
		// in the j's of the first, it will do the multiplication as if those
		// extra rows from the second matrix were not there.
		// However, this class was originally designed for a situation where
		// both MapMatrix's were created from the same base data where this should
		// not be a problem.
		// The resulting matrix will have the uniqueIs of the first matrix
		// and the uniqueJs of the second.
		public function times(b:MapMatrix):MapMatrix {
			var temp:MapMatrix = new MapMatrix();
			var j:String;
			for (j in uniqueJs) {
				if (!b.uniqueIs.hasOwnProperty(j)) {
					throw new Error("a.column doesn't match b.row");
				}
			}

			var accumulator:Number;
			var tempRow:Object;
			var tempColumn:Object;

			for (j in b.uniqueJs) {
				tempColumn = b.getExpandedColumn(j);
				for (var i:String in uniqueIs) {
					tempRow = this.getExpandedRow(i);
					accumulator = 0;
					for (var r:String in uniqueJs) {
						if (tempRow.hasOwnProperty(r)) {
							accumulator += tempRow[r] * tempColumn[r];
						}
					}
					temp.setValue(i, j, accumulator);
				}
			}
			temp.uniqueIs = uniqueIs;
			temp.uniqueJs = b.uniqueJs;
			return temp;
		}

		// Like multiply, this was designed to work when the two MapMatrix's
		// were derived from the same base data.
		// However, it is possible to use even when the two don't perfectly match.
		// If there is no cooresponding cell in the second MapMatrix, it will assume
		// a zero.  If there are extra cells in the second MapMatrix, those will
		// be ignored.  The resulting matrix will have the same shape and key
		// values as the first MapMatrix (this).
		// It will also have the same exact uniqueIs and uniqueJs as the first MapMatrix.
		public function plus(b:MapMatrix):MapMatrix {
			var temp:MapMatrix = new MapMatrix();
			for (var i:String in uniqueIs) {
				for (var j:String in uniqueJs) {
					temp.setValue(i, j, getValue(i, j) + b.getValue(i, j), uniqueIs[i], uniqueJs[j]);
				}
			}
			return temp;
		}

		public function get uniqueIs():Object {
			return _uniqueIs;
		}

		public function set uniqueIs(value:Object):void {
			_uniqueIs = value;
		}

		public function get uniqueJs():Object {
			return _uniqueJs;
		}

		public function set uniqueJs(value:Object):void {
			_uniqueJs = value;
		}

		public function get binary():MapMatrix {
			return new BinaryMapMatrix(this);
		}

		// get irreflexive to make nodes not self-linked
		public function get irreflexive():MapMatrix {
			return new IrreflexiveMapMatrix(this);
		}

		public function get readOnly():MapMatrix {
			return new ReadOnlyMapMatrix(this);
		}

		public function get transposed():MapMatrix {
			return new TransposedMapMatrix(this);
		}

		public function thresholded(threshold:Number):MapMatrix {
			return new ThresholdedMapMatrix(this, threshold);
		}

		public function scaled(multiplier:Number):MapMatrix {
			return new ScaledMapMatrix(this, multiplier);
		}

		public function max():Number {
			var temp:Number = 0;
			for (var i:String in this.uniqueIs) {
				for (var j:String in this.uniqueJs) {
					temp = Math.max(temp, this.getValue(i, j));
				}
			}
			return temp;
		}

		public function toString():String {
			var temp:String = describeType(this).attribute("name").toString() + ":\n";
			temp += "     \t|";
			for (var j:String in this.uniqueJs) {
				temp += j.substr(0, 7) + "\t|";
			}
			temp += "\n--------+";
			for (j in this.uniqueJs) {
				temp += "-------+";
			}
			temp += "\n";
			for (var i:String in this.uniqueIs) {
				temp += i.substr(0, 7) + "\t|";
				for (j in this.uniqueJs) {
					temp += this.getValue(i, j).toString() + "\t|";
				}
				temp += "\n--------+";
				for (j in this.uniqueJs) {
					temp += "-------+";
				}
				temp += "\n";
			}
			return temp;
		}
	}
}

