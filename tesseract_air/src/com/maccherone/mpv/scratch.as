		 public var bugArray:Array = [
	        {"bug_id": 27675, "bug_desc": "Completion box disappearing", "start_when": 12869, "end_when": 12869, "bug_priority":"High", "bug_status":"UNCONFIRMED", "assigned_to": 23706},
	        {"bug_id": 27742, "bug_desc": "New and open doc fail", "start_when": 12470, "end_when": 12774, "bug_priority":"Low", "bug_status":"RESOLVED", "assigned_to": 23706},
	        {"bug_id": 27840, "bug_desc": "crash opening xml file", "start_when": 12467, "end_when": 12774, "bug_priority":"Low", "bug_status":"RESOLVED", "assigned_to": 23706}
	     	];
		
		   public var commitsArr:Array = [
        		{"file_name": "file1.c", "file_id": 11, "cvs_commit_id": 4, "person_id": 21, "name": "john1", "when": 10849},
        		{"file_name": "file2.c", "file_id": 12, "cvs_commit_id": 4, "person_id": 21, "name": "john1", "when": 10849},
        		
        		{"file_name": "file3.c", "file_id": 13, "cvs_commit_id": 2, "person_id": 52, "name": "bob2", "when": 10850},
        		{"file_name": "file4.txt", "file_id": 14, "cvs_commit_id": 2, "person_id": 52, "name": "bob2", "when": 10850},
        		{"file_name": "file5.cpp", "file_id": 15, "cvs_commit_id": 2, "person_id": 52, "name": "bob2", "when": 10850},
        		{"file_name": "file6.java", "file_id": 16, "cvs_commit_id": 2, "person_id": 52, "name": "bob2", "when": 10850},
        		
        		{"file_name": "file1.c", "file_id": 11, "cvs_commit_id": 5, "person_id": 52, "name": "bob2", "when": 10852},
        		{"file_name": "file4.txt", "file_id": 14, "cvs_commit_id": 5, "person_id": 52, "name": "bob2", "when": 10852},
        		{"file_name": "file5.cpp", "file_id": 15, "cvs_commit_id": 5, "person_id": 52, "name": "bob2", "when": 10852},
        		{"file_name": "file8.java", "file_id": 18, "cvs_commit_id": 5, "person_id": 52, "name": "bob2", "when": 10852},
        		
        		{"file_name": "file1.c", "file_id": 11, "cvs_commit_id": 3, "person_id": 36, "name": "jen3", "when": 10869},
       			{"file_name": "file2.c", "file_id": 12, "cvs_commit_id": 3, "person_id": 36, "name": "jen3", "when": 10869},
				{"file_name": "file7.java", "file_id": 17, "cvs_commit_id": 3, "person_id": 36, "name": "jen3", "when": 10869},
        		{"file_name": "file8.java", "file_id": 18, "cvs_commit_id": 3, "person_id": 36, "name": "jen3", "when": 10869},
	       	]
		
		public var communicationArr:Array	= [
        		{"grouping_id": "BA01", "communication_id": 1, "when": 10849, "person_id": 21, "name": "john1", "type": "activity"},
        		{"grouping_id": "BA01", "communication_id": 2, "when": 10850, "person_id": 52, "name": "bob2", "type": "activity"},
        		{"grouping_id": "BC01", "communication_id": 1, "when": 10852, "person_id": 52, "name": "bob2", "type": "comment"},
        		{"grouping_id": "BC01", "communication_id": 2, "when": 10852, "person_id": 36, "name": "jen3", "type": "comment"},
        		{"grouping_id": "EM01", "communication_id": 1, "when": 10852, "person_id": 52, "name": "bob2", "type": "email"},
        		{"grouping_id": "EM01", "communication_id": 2, "when": 10852, "person_id": 36, "name": "jen3", "type": "email"},
        	]
        	
 		private var originalCommitsXML:XML = <root>
 				<commit>
 					<file_name>file1.c</file_name>
 					<file_id>11</file_id>
 					<cvs_commit_id>4</cvs_commit_id>
 					<person_id>21</person_id>
 					<name>john1</name>
 					<when>10849</when>
 				</commit> 				
 				<commit>
 					<file_name>file2.c</file_name>
 					<file_id>12</file_id>
 					<cvs_commit_id>4</cvs_commit_id>
 					<person_id>21</person_id>
 					<name>john1</name>
 					<when>10849</when>
 				</commit>
 				<commit>
 					<file_name>file3.c</file_name>
 					<file_id>13</file_id>
 					<cvs_commit_id>2</cvs_commit_id>
 					<person_id>52</person_id>
 					<name>bob2</name>
 					<when>10850</when>
 				</commit>
 			</root>