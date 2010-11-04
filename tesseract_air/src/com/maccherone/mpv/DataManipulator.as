package com.maccherone.mpv
{

	import com.adobe.flex.extras.controls.springgraph.*;

	import flash.events.Event;

	import mx.charts.chartClasses.IAxis;
	import mx.collections.ArrayCollection;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.events.FlexEvent;
	import mx.formatters.DateFormatter;

	[Bindable]
	public class DataManipulator
	{
		// General/Other
		public var application:mpv;
		static private var _instance:DataManipulator;  // To store one-shot singleton instance
		private var dateFormatter:DateFormatter;
		private var tempGraph:Graph;
		public var names:Array;
		public var personIDToName:Object; // key=personID, value=name
		public var nextName:Number = 0;
		public var projectActivity:ArrayCollection = new ArrayCollection(); // each row: { when: 1234, commits: 35, communication:-39 }


		// Renderers
		public var fToFEdgeRenderer:MPVEdgeRenderer;
		public var fToFViewFactory:MPVViewFactory;
		public var dToDEdgeRenderer:MPVEdgeRenderer;
		public var dToDViewFactory:MPVViewFactory;

		// Style
		public var nodeColor:uint = 0x0000ff;
		public var highlightNodeColor:uint = 0xffcc00;
		public var selectNodeColor:uint = 0xff6600;
		public var edgeColor:uint = 0x999999;
		public var gapEdgeColor:uint = 0xcc0000;
		public var matchEdgeColor:uint =  0x00ff00;
		public var enhancementColor:uint = 0x6699ff;
		public var trivialColor:uint = 0xccffcc;
		public var minorColor:uint = 0xffff33; 
		public var normalColor:uint = 0xffcc33;
		public var majorColor:uint = 0xff9966;
		public var criticalColor:uint = 0xcc0000;
		public var blockerColor:uint = 0xff0000;
		public var projectCommitColor:uint = 0x0000ff;
		public var projectCommunicationColor:uint = 0x336600;

		// Project/Global
		public var projectsXML:XML;
		public var projects:ArrayCollection;
		public var projectID:int = 638;
		public var baseURL:String = "data/"

		public var whenMin:Number;
		public var whenMax:Number;
		public var whenRange:Array = null;

		public var coloredNodes:Object = {}; // key:id, value:actual MPVNode
		public var selectionMode:String = "";  // will be "file", "developer", or "bug"

		// release info
		public var releases:Array=["Release 1.0", "Release 1.2", "Release 1.4", "Release 2.0", "Release 2.2", "Release 2.4", "Release 2.6",
			"Release 2.8", "Release 2.10", "Release 2.12", "Release 2.14", "Release 2.16", "Release 2.18"];
		public var releaseEpochDays:Array=[10654,11103,11415,11865,12089,12307,12509,12677,12852,13034,13244,13398,13587];

		// Communication
		public var commShowEmailFlag:Boolean = true;
		public var commShowCommentFlag:Boolean = true;
		public var commShowActivityFlag:Boolean = true;
		public var commLookBackDays:Number = 0;

		// Commits and F2F
		public var commitsXML:XML;
		public var originalCommits:Array;
		public var commitsCleaned:Array;
		public var commits:Array;

		public var packTree:Object;
		public var isFToF:Boolean = false; // if the parent matrix is FToF or not
		public var dToF:MapMatrix;
		public var fToF:MapMatrix;
		public var pToP:MapMatrix;
		public var fToFGraph:Graph;

		public var fileNumberThreshold:int = 20;
		public var committedTogetherMin: int; // the min committed together timess in f-to-f matrix
		public var committedTogetherMax: int; // the max committed together times in f-to-f matrix
		public var committedTogetherThreshold:int = 2; // TODO: Temporarily set to 2. Change back to 5.
		public static var extensions:Array = [".c", ".cpp", ".h", ".hpp", ".hxx", ".cxx", ".py", ".cs"]; 
		public var selectedExtensions:Array;
		public var files:Array;
		public var packages:Array = new Array();
		public var visibleFileIDs:Object = null; // If null, then all visible, otherwise key specifies which should be visible.  Ignore the value, it may contain MPVNodes from an old graph.
		public var visiblePacks:Object = null;

		// Communication and D2D
		public var communicationXML:XML;
		public var originalCommunication:Array; // Not used yet
		public var communication:Array;

		public var bugIDToD:MapMatrix;
		public var bugIDToF:MapMatrix;
		public var dToD:MapMatrix;
		public var dToDGraph:Graph;

		public var dToDMode:String = "congruence";  // Alternatives are communication and coordinationRequirements

		public var developers:Array;
		public var visibleDeveloperIDs:Object = null; // If null, then all visible, otherwise key specifies which should be visible.  Ignore the value, it may contain MPVNodes from an old graph.

		// Requirements, Behavior and Congruence
		private var coordinationRequirements:MapMatrix;
		private var coordinationBehavior:MapMatrix;
		private var congruence:MapMatrix;

		// Bugs
		public var bugShowEnhancementFlag:Boolean = true;
		public var bugShowTrivialFlag:Boolean = true;
		public var bugShowMinorFlag:Boolean = true;
		public var bugShowNormalFlag:Boolean = true;
		public var bugShowMajorFlag:Boolean = true;
		public var bugShowCriticalFlag:Boolean = true;
		public var bugShowBlockerFlag:Boolean = true;
		public var bugXML:XML;
		public var originalBugs:Array;
		public var bugCommitXML:XML;
		public var bugCommit:Array;
		public var bugs:Array;
		public var openBugs:ArrayCollection;

		public var stopWatch:StopWatch = new StopWatch();

		public var projectCommits:ArrayCollection = new ArrayCollection();

		public var projectCommunication:ArrayCollection = new ArrayCollection();

		public function DataManipulator() {
			if (DataManipulator._instance == null) {
				_instance = this;
				dateFormatter = new DateFormatter();
				dateFormatter.formatString = "YYYY-MM-DD";
					// run test on MapMatrix
//				MapMatrix.test();
			} else {
				throw new Error("Constructor can only be called once. Call getInstance() instead.");
			}
		}

		public function setApplication(application:mpv):void {
			this.application = application;
		}

		public static function getInstance():DataManipulator {
			if (DataManipulator._instance == null) {
				throw new Error("Constructor must be called once before calling getInstance");
			} else {
				return _instance;
			}
		}

		public function fileExtensionPredicate(row:Object):Boolean{
			/* if(selectedExtensions){
			   trace("selectedExtensions = " + selectedExtensions);
			 } */
			if (row["file_name"].indexOf("ChangeLog") >= 0) {
				return false;
			} else if (!selectedExtensions || (selectedExtensions.indexOf("show all") >= 0)) {
				return true;
			} else {
				if(selectedExtensions.indexOf("select all") >=0){
					selectedExtensions = extensions;
				}
				return isValidExtension(row["file_name"]);
			}
			// TODO: Extension filter turned on now
			//return isValidExtension(row["file_name"]);
		}

		public function commitDatePredicate(row:Object):Boolean{
			var flag:Boolean = false;
			if ((row["when"] >= whenRange[0]) && (row["when"] < whenRange[1])){
				flag = true;
			}
			return flag;
		}

		public function commitPredicate(row:Object):Boolean{
			return fileExtensionPredicate(row) && commitDatePredicate(row);
		}

		public function isValidExtension(file:String):Boolean
		{
//			var flag:Boolean = false;
//			for each(var ext:String in extensions) {
//				if (file.indexOf(ext) >= 0) {
//					flag = true;
//				}
//			}
//			return flag;

			var fileParts:Array = file.split(".");
			var extension:String = fileParts[fileParts.length - 1];
			if (selectedExtensions.indexOf("." + extension) >= 0) {
				return true;
			} else {
				return false;
			}
		}

		public function commDatePredicate(row:Object):Boolean{
			var flag:Boolean = false;
			if ((row["when"] >= (whenRange[0] - commLookBackDays)) && (row["when"] < whenRange[1])){
				flag = true;
			}
			return flag;
		}

		public function communicationTypePredicate(row:Object):Boolean{
			return((commShowEmailFlag && (row["type"] == "email")) ||
				(commShowCommentFlag && (row["type"] == "comment")) ||
				(commShowActivityFlag && (row["type"] == "activity")));
		}

		public function communicationPredicate(row:Object):Boolean{
			return communicationTypePredicate(row) && commDatePredicate(row);
		}

		public function bugDatePredicate(row:Object):Boolean{
			var flag:Boolean = false;
			// adding open bugs starting before whenRange[1] by Jianguo Wang
			if (((row["start_when"] >= whenRange[0]) && (row["start_when"] < whenRange[1]))	|| 
				((row["end_when"] >= whenRange[0]) && (row["end_when"] < whenRange[1])) || 
				((row["start_when"] < whenRange[1]) && (row["end_when"] == 0))){
				flag = true;
			}
			return flag;
		}

		// a function to get the release date range of a bug
		public function getBugReleaseInfo(bug:Object):Array{
			var releaseRange:Array = [whenRange[0],whenRange[1]];
			var start:Number = Number(bug["start_when"]);
			var end:Number = Number(bug["end_when"]);
			// Search for the start date and end date of a bug in the release epoch days
			// a better way is to use binary search. Since we don't have a large input, 
			// here I just use regular search.
			for(var i:int = 1; i < releaseEpochDays.length; i++){
				if(releaseEpochDays[i] > start){
					if(end){
						for(var j:int = 1; j<releaseEpochDays.length; j++){
							if(releaseEpochDays[j] >= end){
								releaseRange[0] = releaseEpochDays[i-1];
								releaseRange[1] = releaseEpochDays[j];
								return releaseRange;
							}
						}
					}else{
						releaseRange[0] = releaseEpochDays[i-1];
						releaseRange[1] = releaseEpochDays[i];
						return releaseRange;
					}
				}
			}
			return releaseRange;
		}

		public function bugTypePredicate(row:Object):Boolean{
			var flag:Boolean = false;
			flag = ((bugShowEnhancementFlag && (row["bug_severity"] == "enhancement")) ||
//			return((bugShowEnhancementFlag && (row["bug_severity"] == "enhancement")) ||
				(bugShowTrivialFlag && (row["bug_severity"] == "trivial")) ||
				(bugShowMinorFlag && (row["bug_severity"] == "minor")) ||
				(bugShowNormalFlag && (row["bug_severity"] == "normal")) ||
				(bugShowMajorFlag && (row["bug_severity"] == "major")) ||
				(bugShowCriticalFlag && (row["bug_severity"] == "critical")) ||
				(bugShowBlockerFlag && (row["bug_severity"] == "blocker")));
			return flag;
		}

		public function bugPredicate(row:Object):Boolean{
			return bugTypePredicate(row) && bugDatePredicate(row);
		}

		public function dToDModePredicate(value:Number):Boolean {
			if (value == 0) return false;
			if (dToDMode == "congruence") return true;
			if (dToDMode == "coordinationRequirement") return (value == 3 || value == 2);
			if (dToDMode == "communication") return (value == 1 || value == 3);
			return false;
		}

		// add release information to the tooltip of date range slider bar
		public function toolTipFormatterWithRelease(index:Number):String {
			var regularDate: String; 

			// get regular tooltip
			regularDate = toolTipFormatter(index);
			for(var i:Number=0; i < releases.length; i++){
				if(index == releaseEpochDays[i]){
					// add release information to the tooltip
					regularDate = releases[i]+ "\n" + regularDate;
				}
			}
			return regularDate;
		}

		public function toolTipFormatter(index:Number):String {
			return dateFormatter.format(Utils.dateFromEpochNumber(index));
		}

		public function labelFormatter(labelValue:Object, previousValue:Object, axis:IAxis):String {
			return " " + dateFormatter.format(labelValue) + " ";
		}

		public function startDateFormatter(item:Object, column:DataGridColumn):String {
			if(!item.hasOwnProperty("start_when")){
				return "";
			}else {
				return " " + toolTipFormatter(item.start_when) + " ";	
			}
		}

		public function endDateFormatter(item:Object, column:DataGridColumn):String {
			if(!item.hasOwnProperty("end_when")){
				return "";
			}else {
				return " " + toolTipFormatter(item.end_when) + " ";
			}

		}

		public function calculateProjectActivity():void {
			// TODO: Later break this down so commits and communication are calculated seperatly and only call the communicatoin one when communication flag settings are changes
			projectActivity.removeAll();
			var tempCommitsGrouped:Object = {}; // key=cvs_commit_id, value=when
			for each (var row:* in originalCommits) {
				if (! tempCommitsGrouped.hasOwnProperty(row.cvs_commit_id)) {
					tempCommitsGrouped[row.cvs_commit_id] = row.when;
				}
			}
			// Add the commits
			var xref:Object = {}; // key=date, value=index in projectActivity ArrayCollection
			var tempWhen:Number;
			var tempMinWhen:Number = -1;
			var tempMaxWhen:Number = -1;
			var tempWhenString:String;
			var tempIndex:Number;
			var maxCommits:Number = 0;
			var minCommunication:Number = 0; // Note this is the min because we track communication as negatives
			for each (tempWhen in tempCommitsGrouped) {
//				tempWhen = row.when;
				if (tempMinWhen < 0) {
					tempMinWhen = tempWhen;
					tempMaxWhen = tempWhen;
				} else {
					tempMinWhen = Math.min(tempMinWhen, tempWhen);
					tempMaxWhen = Math.max(tempMaxWhen, tempWhen);
				}
				tempWhenString = tempWhen.toString();
				tempIndex = xref[tempWhenString];
				if (isNaN(tempIndex)) {
					xref[tempWhenString] = projectActivity.length;
					projectActivity.addItem({when:Utils.dateFromEpochNumber(tempWhen), commits:1, communication:0});
				} else {
					projectActivity.getItemAt(tempIndex).commits++;
				}
				maxCommits = Math.max(maxCommits, projectActivity.getItemAt(tempIndex).commits);
			}
			this.whenMax = tempMaxWhen;
			this.whenMin = tempMinWhen;

			// Now add the communication
			for each (row in communication) {
				if (communicationTypePredicate(row)) {
					tempWhen = row.when;
					if (tempMinWhen < 0) {
						tempMinWhen = tempWhen;
						tempMaxWhen = tempWhen;
					} else {
						tempMinWhen = Math.min(tempMinWhen, tempWhen);
						tempMaxWhen = Math.max(tempMaxWhen, tempWhen);
					}
					tempWhenString = tempWhen.toString();
					tempIndex = xref[tempWhenString];
					if (isNaN(tempIndex)) {
						xref[tempWhenString] = projectActivity.length;
						projectActivity.addItem({when:Utils.dateFromEpochNumber(tempWhen), commits:0, communication:-1});
					} else {
						projectActivity.getItemAt(tempIndex).communication--;
					}
					minCommunication = Math.min(minCommunication, projectActivity.getItemAt(tempIndex).communication);
				}
			}
			this.whenMax = tempMaxWhen;
			this.whenMin = tempMinWhen;

			// Normalize communication and commits to the same scale and put on log scale
			var logMaxCommits:Number = Math.log(maxCommits);
			var logMinCommunication:Number = -Math.log(-minCommunication);
			for each (row in projectActivity) {
//				trace("Before:" + row.when + " commits:" + row.commits + " communication:" + row.communication);
				if (row.commits > 0.0) {
					row.commits = Math.log(row.commits)/logMaxCommits;
				}
				if (row.communication < 0.0) {
					row.communication = Math.log(-row.communication)/logMinCommunication;
				}
//				trace(row.when + " commits:" + row.commits + " communication:" + row.communication);
			}
		}

		public function calculateOpenBugs():void {
			var temp:ArrayCollection = new ArrayCollection();
			var tempObject:Object;
			for (var i:Number = whenRange[0]; i <= whenRange[1]; i++) {
				tempObject = {date:Utils.dateFromEpochNumber(i)};
				for each (var row:Object in bugs) {
					if ((row.start_when < i) && (i <= row.end_when)) {
//						trace("start:" + row.start_when + " < i:" + i + " <= end:" + row.end_when);
						if (tempObject.hasOwnProperty(row.bug_severity)) {
							tempObject[row.bug_severity]++;
						} else {
							tempObject[row.bug_severity] = 1;
						}
					}
				}
				temp.addItem(tempObject);
			}
//			for each (var tempRow:Object in temp) {
//				trace("date:"+tempRow.date + 
//						"enhancement:"+tempRow.enhancement + 
//						"trivial:"+tempRow.trivial +
//						"minor:"+tempRow.minor + 
//						"normal:"+tempRow.normal + 
//						"major:"+tempRow.major + 
//						"critical:"+tempRow.critical + 
//						"blocker:"+tempRow.blocker
//					);
//			}
			openBugs = temp;
		}

		public function isABugRowPredicate(row:Object):Boolean {
			return (row.type == "activity") || (row.type == "comment");
		}

		public function calculateBugIDToD():void {
			bugIDToD = MapMatrix.fromCollection(communication, "id", "person_id"
				, null, null, isABugRowPredicate);
		}

		public function calculateBugIDToF():void { 
			bugIDToF = new MapMatrix();
			var tempBugIDToCommitID:MapMatrix = MapMatrix.fromCollection(bugCommit, "bug_id", "cvs_commit_id"
				, null, null, null);
			var tempCommitIDToFileID:MapMatrix = MapMatrix.fromCollection(commitsCleaned, "cvs_commit_id", "file_id"
				, null, null, null);
			for (var i:String in tempBugIDToCommitID.uniqueIs) {
				var tempRow:Object = tempBugIDToCommitID.getRow(i);
				for (var i2:String in tempRow) {
					var tempRow2:Object = tempCommitIDToFileID.getRow(i2);
					for (var i3:String in tempRow2) {
						bugIDToF.setValue(i, i3, 1);
					}
				}
			}
		}

		public function backgroundClickClear(event:Event):void {
			if (event.target is SpringGraph) {
				clearAllColor();
			}
		}

		public function clearAllColor():void {
			clearNodeColor();
			clearListColor();
			selectionMode = "";
		}

		public function clearNodeColor():void {
			for each (var h:Object in coloredNodes) {
				h.setStyle("backgroundColor", nodeColor);
			}
			coloredNodes = {};
		}

		public function  clearListColor():void {
			application.fileList.selectedIndices = [];
			application.developerList.selectedIndices = [];
		/* application.bugList.selectedIndices = [];
		   application.dgBug.selectedIndices = [];
		 application.moreBugsLikeThis.selectedIndices = [];  */
		}

//		public function isSelected(node:MPVNode):Boolean {
//			var nodeID:String = node.data.id;
//			return selectedNodes.hasOwnProperty(nodeID);
//		}

//		public function getSelectedIDs():Array {
//			var tempIndices:Array;
//			var tempIDs:Array = [];
//			if (this.selectionMode = "file") {
//				this.application.fileList.selectedIndices;
//				this.files.
//			}
//		}

//		public function getSelectedNodes():Array {
//			
//			
//			return null;
//		}

		public function developerNodeClick(d:String):void {
			this.clearAllColor();
			this.developerNodeControlClick(d);
		}

		public function fileNodeClick(f:String):void {
			this.clearAllColor();
			this.fileNodeControlClick(f);
		}

		// a function to handle click on a package node
		public function packageNodeClick(f:String):void{
			this.clearAllColor();
			this.packageNodeControlClick(f);
		}

		// a function to handle ctrl click on a package node
		public function packageNodeControlClick(f:String):void{
			var fileIDs:Array = this.packToFileIDs(f);
			for each(var file:String in fileIDs){
				this.fileNodeControlClick(file);
			}
		}

		// a function to handle double click on a package node
		public function packageNodeDoubleClick(p:String):void {
			// if the node double clicked is a package, explore and display 
			// the children nodes in it
			this.updatePackList(p);
			this.calculateAndDisplayPToP();

		}

		public function developerNodeControlClick(d:String):void {
			this.selectionMode = "developer";
			this.colorDeveloper(d, this.selectNodeColor);
			var fileIDsToHighlight:Object = this.dToF.getRow(d);
			for (var i:String in fileIDsToHighlight) {
				this.colorFile(i, this.highlightNodeColor);
			}
		}

		public function fileNodeControlClick(f:String):void {
			this.selectionMode = "file";
			this.colorFile(f, this.selectNodeColor);
			var developerIDsToHighlight:Object = this.dToF.getColumn(f);
			for (var i:String in developerIDsToHighlight) {
				this.colorDeveloper(i, this.highlightNodeColor);
			}		
		}

		public function colorDevelopers(toHighlight:Object, color:uint):void {
			for (var d:String in toHighlight) {
				colorDeveloperNode(d,color);
			}

			var tempSelectedItems:Array = [];
			for each (var item:Object in this.developers) {
				if (toHighlight.hasOwnProperty(item.id)) {
					tempSelectedItems.push(item);
				}
			}
			application.developerList.selectedItems = tempSelectedItems;
		}

		public function colorDeveloperNode(d:String, color:uint):void {
			var tempNode:MPVNode;
			if (dToDGraph.hasNode(d)) {
				tempNode = MPVNode(Item(dToDGraph.nodes[d]).data["MPVNode"]);
				tempNode.setStyle("backgroundColor", color)
				coloredNodes[d] = tempNode;
			}			
		}

		public function colorDeveloper(d:String, color:uint):void {
			// Colors Node
			colorDeveloperNode(d, color);

			// Colors List entry
			var tempIndex:int;
			var foundOne:Boolean = false;
			for (var i:int=0; i<developers.length; i++) {
//				trace("i:" + i);
//				trace("developers[i].id" + developers[i].id);
				if (developers[i].id == d) {
					tempIndex = i;
					foundOne = true;
					break;
				}
			}
			if (foundOne) {
				var tempSelectedIndices:Array = application.developerList.selectedIndices;
				tempSelectedIndices.push(tempIndex);
				application.developerList.selectedIndices = tempSelectedIndices;
			}

			application.developerList.setStyle("selectionColor", color);
		}

		public function colorFiles(toHighlight:Object, color:uint):void {
			for (var f:String in toHighlight) {
				colorFileNode(f,color);
			}

			var tempSelectedItems:Array = [];
			for each (var item:Object in this.files) {
				if (toHighlight.hasOwnProperty(item.id)) {
					tempSelectedItems.push(item);
				}
			}
			application.fileList.selectedItems = tempSelectedItems;
		}

		// get package name from file ID
		public function fileIDToPack(fileID:String):String{
			var fileName:String = fToF.uniqueIs[fileID].file_name;
			return this.getParentPack(fileName);
		}

		// get file IDs in a visible package
		public function packToFileIDs(packName:String):Array{
			var fileIDs:Array = [];
			for each (var item:Object in this.files) {
				if ((item.file_name as String).indexOf(packName) == 0) {
					fileIDs.push(item.id);
				}
			}
			return fileIDs;
		}

		// file name to file id 
		public function fileNameToId(fileName:String):String{
			for each (var item:Object in this.files) {
				if(item.file_name == fileName){
					return item.id;
				}
			}
			return fileName;
		}

		public function colorFileNode(f:String, color:uint):void {
			var tempNode:MPVNode;

			// get package name if its parent package is in the F-F graph
			if(!isFToF && fToF.getReflexiveLinkCount(f) >= 0){
				f = this.fileIDToPack(f);
			}

			if (fToFGraph.hasNode(f)) {
//				trace("fToFGraph.hasNode " + f);
				tempNode = MPVNode(Item(fToFGraph.nodes[f]).data["MPVNode"]);
				tempNode.setStyle("backgroundColor", color)
				coloredNodes[f] = tempNode;
			}
		}

		public function colorFile(f:String, color:uint):void {
			// Colors Node
			colorFileNode(f, color);

			// Colors List entry
			var tempIndex:int;
			var foundOne:Boolean = false;
			for (var i:int=0; i<files.length; i++) {
				if (files[i].id == f) {
					tempIndex = i;
					foundOne = true;
					break;
				}
			}
			if (foundOne) {
				var tempSelectedIndices:Array = application.fileList.selectedIndices;
				tempSelectedIndices.push(tempIndex);
				application.fileList.selectedIndices = tempSelectedIndices;
			}

			application.fileList.setStyle("selectionColor", color);
		}

		public function colorBug(b:String, color:uint):void {
			// Colors List entry
			var tempIndex:int;
			var foundOne:Boolean = false;
			for (var i:int=0; i<bugs.length; i++) {
				if ((bugs[i].bug_id as Number).toString() == b) {
					tempIndex = i;
					foundOne = true;
					break;
				}
			}
			if (foundOne) {
				var tempSelectedIndices:Array = application.bugList.selectedIndices;
				tempSelectedIndices.push(tempIndex);
				application.bugList.selectedIndices = tempSelectedIndices;
			}

			application.bugList.setStyle("selectionColor", color);
		}

		/* public function highlightFromBugListClick(selectedIndices:Array):void {
		   //			clearAllColor();
		   clearNodeColor();
		   application.fileList.selectedIndices = [];
		   application.developerList.selectedIndices = [];
		   var tempDeveloperObject:Object;
		   var tempFileObject:Object;
		   var tempBug:Object;
		   var developerNodesToHighlight:Object = {};
		   var fileNodesToHighlight:Object = {};
		   for each (var index:* in selectedIndices) {
		   tempBug = this.bugs[index];
		   tempDeveloperObject = bugIDToD.getRow(tempBug.bug_id);
		   tempFileObject = bugIDToF.getRow(tempBug.bug_id);
		   Utils.mergeObjects(developerNodesToHighlight, tempDeveloperObject);
		   Utils.mergeObjects(fileNodesToHighlight, tempFileObject);
		   }
		   for (var i:String in developerNodesToHighlight) {
		   colorDeveloper(i, this.highlightNodeColor);
		   }
		   for (var i2:String in fileNodesToHighlight) {
		   colorFile(i2, this.highlightNodeColor);
		   }
		 } */


		public function highlightFromBugListClick(selectedBugs:Array):void {
//			clearAllColor();
			clearNodeColor();	
			application.fileList.selectedIndices = [];
			application.developerList.selectedIndices = [];					
			var tempDeveloperObject:Object;
			var tempFileObject:Object;
			var developerNodesToHighlight:Object = {};
			var fileNodesToHighlight:Object = {};
			for each (var tempBug:Object in selectedBugs) {
				tempDeveloperObject = bugIDToD.getRow(tempBug.bug_id);
				tempFileObject = bugIDToF.getRow(tempBug.bug_id);
				Utils.mergeObjects(developerNodesToHighlight, tempDeveloperObject);
				Utils.mergeObjects(fileNodesToHighlight, tempFileObject);
			}
			for (var i:String in developerNodesToHighlight) {
				colorDeveloper(i, this.highlightNodeColor);
			}
			for (var i2:String in fileNodesToHighlight) {
				colorFile(i2, this.highlightNodeColor);
			}
		}

		public function fileListClick():void {
			var selectedItems:Array = application.fileList.selectedItems;
			clearAllColor();
			var tempObject:Object;
			var tempID:String;
			var otherGraphNodesToHighlight:Object = {};
			for each (var item:* in selectedItems) {
				tempID = item.id;
				this.colorFile(tempID, this.selectNodeColor);
				tempObject = this.dToF.getColumn(tempID);
				Utils.mergeObjects(otherGraphNodesToHighlight, tempObject);
			}

			colorDevelopers(otherGraphNodesToHighlight, this.highlightNodeColor);
			application.developerList.setStyle("selectionColor", this.highlightNodeColor);

			// TODO: when we have connection from bugs to files add that here
		}

		public function developerListClick():void {
			var selectedItems:Array = application.developerList.selectedItems;
			clearAllColor();
			var tempObject:Object;
			var tempID:String;
			var otherGraphNodesToHighlight:Object = {};
			for each (var item:* in selectedItems) {
				tempID = item.id;
				this.colorDeveloper(tempID, this.selectNodeColor);
				tempObject = this.dToF.getRow(tempID);
				Utils.mergeObjects(otherGraphNodesToHighlight, tempObject);
			}

			colorFiles(otherGraphNodesToHighlight, this.highlightNodeColor);
			application.fileList.setStyle("selectionColor", this.highlightNodeColor);

			// TODO: when we have connection from bugs to files add that here
		}

		public function searchHighlight(event:FlexEvent):void {
			clearAllColor();

			// changed to search the developer list
			for each (var d:Object in this.developers) {
				if ((d.name as String).indexOf(event.currentTarget.text) >= 0) {
					colorDeveloper(d.id, this.highlightNodeColor);
				}
			}

			/* for each (var d:Item in dToDGraph.nodes) {
			   if (d.data["MPVNode"].toolTip.indexOf(event.currentTarget.text) >= 0) {
			   colorDeveloper(d.id, this.highlightNodeColor);
			   }
			 } */

			// changed to search the files in diaplay list
			for each (var f:Object in this.files) {
				if ((f.file_name as String).indexOf(event.currentTarget.text) >= 0) {
					colorFile(f.id, this.highlightNodeColor);
				}
			}

			/* for each (var f:Item in fToFGraph.nodes) {
			   if (f.data["MPVNode"].toolTip.indexOf(event.currentTarget.text) >= 0) {
			   colorFile(f.id, this.highlightNodeColor);
			   }
			 } */

			/* for each (var b:Object in bugs) {
			   trace(b.id);
			 } */
			// TODO: Add for bugs. Search
			for each (var b:Object in this.bugs) {
				var bugId:String = (b.bug_id as Number).toString();
				if ((bugId).indexOf(event.currentTarget.text) >= 0) {
					colorBug(bugId, this.highlightNodeColor);
				}
			}
		}

		// build the package tree structure from original commits
		public function buildPackTree():void{
			packTree = new Object();
			// get package structure from commitsCleaned
			for each (var row:Object in commitsCleaned){
				var fileName:String = row.file_name;
				// build packTree if the file is in a package
				if(fileName.indexOf("/") >= 0){
					var fileParts:Array = fileName.match(/[^\/]+\//g);
					if(fileParts)
						var packName:String = fileParts[0];// top package
					// add top package to the pack tree if it's not in the list
					if(!packTree.hasOwnProperty(packName)){
						packTree[packName] = [];
					}

					// manipulate sub packages
					for(var i:int = 0; i < fileParts.length-1; i++){
						var subPackName:String = packName+fileParts[i+1]; // get sub package name

						if(packTree.hasOwnProperty(packName) && packTree[packName].indexOf(subPackName) < 0){
							// push sub pachage to the package's children list
							packTree[packName].push(subPackName); 
						}
						if(!packTree.hasOwnProperty(subPackName)){
							// add sub package to the pack tree. 
							packTree[subPackName] = [];
						}

						packName = subPackName;// do the same with sub package in next loop
					}
				}
			}
		}

		public function calculateCommitsCleaned():void {
			// Finding how many files were in each commit
			var commitIDToF:MapMatrix = MapMatrix.fromCollection(originalCommits, "cvs_commit_id", "file_id", 
				function(row:Object):Object{return {"when": row.when}},
				function(row:Object):Object{return {"file_name": row.file_name}});
			var filesInCommit:Object = {}; // key=cvs_commit_id, value=count
			var count:int;
			var row:Object;
			for (var i:String in commitIDToF.uniqueIs){
				row = commitIDToF.getRow(i);
				count = 0;
				for (var j:String in row) {
					count++;
				}
				filesInCommit[i] = count;
			}
			// Now create commitsCleaned which will not have invalid file extensions and will have a files_in_commit column
			commitsCleaned = [];
			for each (row in originalCommits) {
				if (fileExtensionPredicate(row)) {
					row["files_in_commit"] = filesInCommit[row["cvs_commit_id"]];
					commitsCleaned.push(row);
				}
			}
			// build package tree structure from commitsCleaned
			buildPackTree();	
		}	

		// a function to check if the selected project has multiple packages
		public function hasMultiPackages():Boolean{
			var prePack:String;

			for (var pack:String in packTree) {

				// get top package for each package
				pack = (pack.split("/"))[0];

				// initialize first package
				if(!prePack){
					prePack = pack;
					continue;
				}

				// return true if the project has multiple packages
				if(pack != prePack){
					return true;
				}
			}

			return false;
		}

		// a function to update the package list when exploring into a package
		public function updatePackList(packToExplore:String):void{

			// remove this package from the pacakges list
			packages.splice(packages.indexOf(packToExplore),1);	

			// add sub packages in the package to explore to the packages list
			if(packTree.hasOwnProperty(packToExplore))
				packages = packages.concat(packTree[packToExplore]);
		}

		public function calculateVisiblePacks():void{
			// update visible nodes if the parent graph is p-p and visibleFileIDs is not null
			if(!isFToF && this.visibleFileIDs){
				visiblePacks = {};
				for (var fileID:String in this.visibleFileIDs){
					// push the name of the corresponding package or file
					var name:String = this.fileIDToPack(fileID);
					if(!visiblePacks.hasOwnProperty(name))
						visiblePacks[name] = true;
				}
			}
		}

		public function calculateFilesList():void{
			// Calculate list
			var tempList:Array = [];
			var tempObject:Object;
			for (var i:String in fToF.uniqueIs) {
				if (((this.visibleFileIDs == null) || this.visibleFileIDs.hasOwnProperty(i)) 
					&& fToF.getReflexiveLinkCount(i) > 0) { // filter orphan nodes by link count check
					tempObject = {id:i, file_name:fToF.uniqueIs[i].file_name};
					tempList.push(tempObject);
				}
			}
			files = tempList;
			application.fileList.dataProvider = files;
		}

		// a function to add top packages to the package list
		public function addTopPackages():void{
			for (var pack:String in packTree){
				if(pack.match(/[^\/]+\//g).length == 1){
					packages.push(pack);
				}
			}
		}

		// get parent package for a file if its parent package is in the package list
		public function getParentPack(fileName:String):String{
			// return the parent package if it is in the package list
			for each (var p:String in packages){
				if(fileName.indexOf(p)== 0){
					return p;
				}
			}

			// return the fileName if its parent package is not in the package list
			return fileName; 
		}

		// a function to calcuate the top level package relations based on the f-to-f matrix
		/* public function getTopLevelMatrix():MapMatrix {
		   var topPToP: MapMatrix = new MapMatrix();

		   // calculate the package relations by manipulating the file names in f-to-f matrix
		   // don't use for each statement for this
		   for (var i:String in fToF.uniqueIs) {
		   for (var j:String in fToF.uniqueJs) {
		   var f1:String = fToF.uniqueIs[i].file_name;
		   var f2:String = fToF.uniqueIs[j].file_name;

		   // get top package for each file
		   var p1:String = f1.match(/[^\/]+\//)[0];
		   var p2:String = f2.match(/[^\/]+\//)[0];

		   // add the package-to-package relation to the top level package-to-package matrix
		   topPToP.plusEquals(p1,p2,fToF.getValue(i,j),{"file_name":p1},{"file_name":p2});
		   }
		   }
		   return topPToP;
		 } */

		// calculate next level package to package matrix
		public function calculatePToP():MapMatrix {
			var tempPToP: MapMatrix = new MapMatrix();

			// calculate the package relations by manipulating the file names in f-to-f matrix
			// don't use "for each" statement for this
			for (var i:String in fToF.uniqueIs) {
				for (var j:String in fToF.uniqueJs) {
					var f1:String = fToF.uniqueIs[i].file_name;
					var f2:String = fToF.uniqueIs[j].file_name;

					// get parent package if its parent package is in the package list
					var p1:String = getParentPack(f1);
					var p2:String = getParentPack(f2);

					// add the package-to-package relation to the top level package-to-package matrix
					tempPToP.plusEquals(p1,p2,fToF.getValue(i,j),{"file_name":p1},{"file_name":p2});
				}
			}

			return tempPToP;
		}

//		// a function to display a pToP matrix in spring graph
//		public function displayPToP(pToPMatrix:MapMatrix):void {
//			tempGraph = new Graph();
//			fToFEdgeRenderer = new MPVEdgeRenderer();
//			fToFEdgeRenderer.colorMatrix = pToPMatrix;
//			fToFEdgeRenderer.thicknessMatrix = pToPMatrix;
//			fToFEdgeRenderer.colorMap = {'1':edgeColor};
//			fToFEdgeRenderer.defaultColor = edgeColor;
//			fToFViewFactory = new MPVViewFactory();
//			fToFViewFactory.parentGraph = tempGraph;
//			pToPMatrix.populateGraph(tempGraph, false, null, this.visibleFileIDs);
//			fToFGraph = tempGraph;
//		}

		// a function to display a pToP matrix in spring graph
		public function displayPToP():void {
			tempGraph = new Graph();
			fToFEdgeRenderer = new MPVEdgeRenderer();
			fToFEdgeRenderer.colorMatrix = pToP;
			fToFEdgeRenderer.thicknessMatrix = pToP;
			fToFEdgeRenderer.colorMap = {'1':edgeColor};
			fToFEdgeRenderer.defaultColor = edgeColor;
			fToFViewFactory = new MPVViewFactory();
			fToFViewFactory.parentGraph = tempGraph;
			if(isFToF){
				pToP.populateGraph(tempGraph, false, null, this.visibleFileIDs);
			}else{
				pToP.populateGraph(tempGraph, false, null, this.visiblePacks);
			}
			fToFGraph = tempGraph;
		}

		// calculate and display next level package to package matrix, 
		// called when a package node is double clicked
		public function calculateAndDisplayPToP():void {
			clearAllColor();
			this.application.fToF.empty();
			this.pToP = calculatePToP();
			this.calculateFilesList();
			this.calculateVisiblePacks();
			displayPToP();
			this.application.fToF.forceDirectedLayout.damper=0.3;
			this.application.fToF.dataProvider = fToFGraph;

		}

		public function calculateFToFGraph():void {
			// filter commitsCleaned down to those with the right dates and # of files
			commits = [];
			for each (var row:Object in commitsCleaned) {
//				trace("row.files_in_commit" + row.files_in_commit);
				if (commitPredicate(row) && row.files_in_commit < fileNumberThreshold) {
					commits.push(row);
				}
			}

			var fToFUnthresholded:MapMatrix = MapMatrix.clusterByI(commits, "cvs_commit_id", "file_id", 
				function(row:Object):Object{return {"when": row.when}},
				function(row:Object):Object{return {"file_name": row.file_name}},
				null);

			// get the max committed together times, used to set the committed together threshold maximum
			committedTogetherMax = Math.max(fToFUnthresholded.max(),this.application.committedTogetherThreshold.value); 

			// set the min committed together times, used to set the commintted together threshold minimum
			if(committedTogetherMax == 0){
				committedTogetherMin = 0;
			}else {
				committedTogetherMin = 1; 
			}
//			trace("committedTogetherMax = " + committedTogetherMax);

			fToF = fToFUnthresholded.thresholded(committedTogetherThreshold);
			dToF = MapMatrix.fromCollection(commits, "person_id", "file_id", 
				function(row:Object):Object{return {"name": row.name}},
				function(row:Object):Object{return {"file_name": row.file_name}},
				null);

			/* tempGraph = new Graph();
			   fToFEdgeRenderer = new MPVEdgeRenderer();
			   fToFEdgeRenderer.colorMatrix = fToF;
			   fToFEdgeRenderer.thicknessMatrix = fToF;
			   fToFEdgeRenderer.colorMap = {'1':edgeColor};
			   fToFEdgeRenderer.defaultColor = edgeColor;
			   fToFViewFactory = new MPVViewFactory();
			   fToFViewFactory.parentGraph = tempGraph;
			   fToF.populateGraph(tempGraph, false, null, this.visibleFileIDs);
			 fToFGraph = tempGraph; */

			if(packages.length != 0){
				pToP = this.calculatePToP();
				isFToF = false;
			}else if(hasMultiPackages()){
//				pToP = this.getTopLevelMatrix();
				addTopPackages();
				pToP = this.calculatePToP();
				isFToF = false;

			}else{
				pToP = fToF;
				isFToF = true;
			}

			this.calculateFilesList();
			this.calculateVisiblePacks();
			this.displayPToP();

//			trace("f-to-f matrix:\n" + fToF);
		}

		public function calculateDToDGraph():void {
			calculateProjectActivity();
			stopWatch.interval("Starting calculating coordinationRequirements");
//	       	var coordinationRequirementsByFileOnly:MapMatrix = MapMatrix.clusterByI(commits, "file_id", "person_id",
//	       		function(row:Object):Object{return {"file_id": row.file_id}},
//	       		function(row:Object):Object{return {"name": row.name}});
			coordinationRequirements = dToF.times(fToF).times(dToF.transposed);
//	       	coordinationRequirements = fToF.times(fToF);

			stopWatch.interval("Starting calculating coordinationBahavior");
			coordinationBehavior = MapMatrix.clusterByI(communication, "grouping_id", "person_id",
				function(row:Object):Object{return {"when": row.when, "communication_id": row.communication_id}},
				function(row:Object):Object{return {"name": row.name}},
				communicationPredicate);

			stopWatch.interval("Starting calculating tempCR");
			var tempCR:MapMatrix = coordinationRequirements.thresholded(1).binary.scaled(2); //threshold possibly can be number and then we need binary
			stopWatch.interval("Starting calculating tempCB");
			//threshold possibly can be number and then we need binary
			// also get irreflexive to eliminate the diagonal values
			var tempCB:MapMatrix = coordinationBehavior.thresholded(1).binary.scaled(1).irreflexive; 			
			stopWatch.interval("Starting calculating congruence");
			congruence = tempCR.plus(tempCB);
//			trace("CR:\n"+tempCR);
//			trace("CB:\n"+tempCB);
			dToD = congruence;

			stopWatch.interval("Starting calculating dToDGraph");
			tempGraph = new Graph();
			dToDEdgeRenderer = new MPVEdgeRenderer();
			dToDEdgeRenderer.colorMatrix = dToD;
			if (dToDMode == "congruence") {
				dToDEdgeRenderer.colorMap = {'1':edgeColor, '3':matchEdgeColor, '2': gapEdgeColor};
				dToDEdgeRenderer.thicknessMatrix = coordinationBehavior;
			} else if (dToDMode == "communication") {
				dToDEdgeRenderer.colorMap = {'1':matchEdgeColor, '3':matchEdgeColor, '2': matchEdgeColor};
				dToDEdgeRenderer.thicknessMatrix = coordinationBehavior;
			} else {
				dToDEdgeRenderer.colorMap = {'1':edgeColor, '3':edgeColor, '2': edgeColor};
				dToDEdgeRenderer.thicknessMatrix = coordinationRequirements;
			}
			dToDEdgeRenderer.defaultColor = edgeColor;
			dToDViewFactory = new MPVViewFactory();
			dToDViewFactory.parentGraph = tempGraph;
			dToD.populateGraph(tempGraph, false, dToDModePredicate, this.visibleDeveloperIDs);
			dToDGraph = tempGraph;	 

			// Calculate list
			var tempList:Array = [];
			var tempObject:Object;
			for (var i:String in dToD.uniqueIs) {
				if (((this.visibleDeveloperIDs == null) || this.visibleDeveloperIDs.hasOwnProperty(i))
					&& this.dToD.getReflexiveLinkCount(i) > 0) {// filter nodes without any links
					tempObject = {id:i, name:dToD.uniqueIs[i].name};
					tempList.push(tempObject);
				}
			}
			developers = tempList;
			application.developerList.dataProvider = developers;
//			trace("d-to-f:\n" + dToF);	
//			trace("d-to-d matrix:\n" + dToD);   
//			trace("bug-to-f matrix: \n" + this.bugIDToF);    
//			trace("bug-to-d matrix: \n" + this.bugIDToD);	     
		}

	}
}

