package com.maccherone.mpv
{
	public class Utils
	{
		public static const millisecondsPerDay:int = 1000 * 60 * 60 * 24;

		public function Utils()
		{
		}

		public static function XMLListToArray(xmlList:XMLList):Array {
			var temp:Array = []
			var tempObject:Object;
			var tempString:String;
			var tempNumber:Number;
			for each (var row:XML in xmlList) {
				tempObject = {};
				for each (var element:XML in row.*) {
					tempString = element.toString();
					tempNumber = Number(tempString);
					if (isNaN(tempNumber)) {
						tempObject[element.localName()] = tempString;
					} else {
						tempObject[element.localName()] = tempNumber;
					}
				}
				temp.push(tempObject);
			}
			return temp;
		}

		public static function TXTToArray(txtContents:String):Array {
			var lineEnd:String = "\r\n";
			var temp:Array = txtContents.split(lineEnd);
			return temp;
		}

		// TODO: Move this to it's own class
		public static function obfuscateNames(contents:Array, names:Array, nextName:Number, personIDToName:Object):Number {
			for each (var o:Object in contents) {
				if (o.hasOwnProperty("name") && o.hasOwnProperty("person_id")) {
					if (personIDToName.hasOwnProperty(o.person_id)) {
						o.name = personIDToName[o.person_id];
					} else {
						o.name = names[nextName];
						personIDToName[o.person_id] = o.name;
						if (nextName >= names.length) {
							throw("Not enough names");
						} else {
							nextName++;
						}
					}
				}
			}
			return nextName;
		}

		public static function removeExtras(source:Array, mustContain:Object, key:String):Array {
			var temp:Array =[];
			for each (var row:Object in source) {
				if (row.hasOwnProperty(key) && mustContain.hasOwnProperty(row[key])){
					temp.push(row);
				}
			}
			return temp;
		}

		public static function filterBy(source:Array, predicate:Function):Array{
			var temp:Array =[];
			for each (var row:Object in source) {
				if (predicate(row)){
					temp.push(row);
				}
			}
			return temp;
		}

		public static function dateFromEpochNumber(when:Number):Date {
			return new Date(millisecondsPerDay * when);
		}

		public static function mergeObjects(o1:Object, o2:Object):void {
			// Merges the second parameter (o2) into the first (o1)
			// If there is a duplicate, the item from o2 will overwrite
			// This is fine because it is intended to be used in places
			// where they come from the same source.  This is really a union
			// operation.
			for (var s:String in o2) {
				o1[s] = o2[s];
			}
		}

		public static function removeZeroFromStrField(objList:Array, fieldName:String):void
		{
			for each(var obj:Object in objList){
				if(obj[fieldName] == 0)
					obj[fieldName] = "";
			}
		}
	}
}

