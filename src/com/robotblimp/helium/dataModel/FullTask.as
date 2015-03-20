package com.robotblimp.helium.dataModel
{
	import com.robotblimp.helium.constants.Source;
	import com.robotblimp.helium.core.GraphManager;
	import com.robotblimp.helium.services.db.Database;
	
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	
	import mx.collections.ArrayCollection;
	
	//a task, and its notes, files, tags, and displayIndex
	[Bindable]
	public class FullTask
	{
		public static const ShareType_Share:uint = 1;
		public static const ShareType_Delegate:uint = 2;
		
		public var taskGUID:String;
		public var userGUID:String;
		public var projectGUID:String;
		public var projectDisplayIndex:int;
		public var title:String;
		public var status:uint;
		public var startDate:Number = 0;
		public var dueDate:Number = 0;
		public var organizeBox:uint;
		public var boxDisplayIndex:int;
		public var source:uint;
		public var sourceProfileGUID:String;
		public var linkGroupGUID:String;
		
		public var dateCreated:Number;
		public var dateModified:Number;
		public var dateArchived:Number;
		public var systemType:int;
		
		public var notes:ArrayCollection;
		public var firstNotes:ArrayCollection;
		public var restNotes:ArrayCollection;		
		public var files:ArrayCollection;
		public var tags:ArrayCollection;
		
		public var graphGroupMembers:ArrayCollection;
		
		public var projectTitle:String;
			
		public var isSelected:Boolean;
		public var shouldEdit:Boolean;
	
		
		public function FullTask()		
		{	
		}
		
		public function copyProperties(obj:Object):void
		{
			if(obj.taskGUID) taskGUID = String(obj.taskGUID);
			if(obj.userGUID) userGUID = String(obj.userGUID);
			if(obj.projectGUID) projectGUID = String(obj.projectGUID);
			if(obj.projectDisplayIndex) projectDisplayIndex = int(obj.projectDisplayIndex);
			if(obj.title) title = String(obj.title);
			if(obj.status) status = uint(obj.status);
			if(obj.startDate) startDate = Number(obj.startDate);
			if(obj.dueDate) dueDate = Number(obj.dueDate);
			if(obj.organizeBox) organizeBox = uint(obj.organizeBox);
			if(obj.boxDisplayIndex) boxDisplayIndex = int(obj.boxDisplayIndex);
			if(obj.source) source = uint(obj.source);
			if(obj.sourceProfileGUID) sourceProfileGUID = String(obj.sourceProfileGUID);
			if(obj.linkGroupGUID) linkGroupGUID = String(obj.linkGroupGUID);
			if(obj.dateCreated) dateCreated = Number(obj.dateCreated);
			if(obj.dateModified) dateModified = Number(obj.dateModified);
			if(obj.dateArchived) dateArchived = Number(obj.dateArchived);
			if(obj.systemType) systemType = int(obj.systemType);
			
			if(obj.notes) notes = ArrayCollection(obj.notes);
			if(obj.firstNotes) firstNotes = ArrayCollection(obj.firstNotes);
			if(obj.restNotes) restNotes = ArrayCollection(obj.restNotes);		
			if(obj.files) files = ArrayCollection(obj.files);
			if(obj.tags) tags = ArrayCollection(obj.tags);
			
			if(obj.graphGroupMembers) graphGroupMembers = ArrayCollection(obj.graphGroupMembers);
			
			if(obj.projectTitle) projectTitle = String(obj.projectTitle);
			
			if(obj.isSelected) isSelected = Boolean(obj.isSelected);
			if(obj.shouldEdit) shouldEdit = Boolean(obj.shouldEdit);
		}
		
		public function update(DB:Database):void
		{
			var sql:SQLStatement = new SQLStatement();
			sql.text = "UPDATE task " + 
					"SET " +
					" projectGUID=:ProjectGUID " + 
					",projectDisplayIndex=:ProjectDisplayIndex " + 
					",title=:Title " +
					",status=:Status " +
					",startDate=:StartDate " +
					",dueDate=:DueDate " +
					",organizeBox=:OrganizeBox " +
					",source=:Source " +
					",sourceProfileGUID=:SourceProfileGUID " +
					",linkGroupGUID=:LinkGroupGUID " +
					",boxDisplayIndex=:DisplayIndex " +					
					",dateModified=strftime('%s','now') " +
					",dateArchived=:DateArchived " +
					",systemType=:SystemType " + 
					"WHERE taskGUID=:TaskGUID ";
			
			sql.parameters[":TaskGUID"] = taskGUID;
			sql.parameters[":ProjectGUID"] = projectGUID;
			sql.parameters[":ProjectDisplayIndex"] = projectDisplayIndex;
			sql.parameters[":Title"] = title;
			sql.parameters[":Status"] = status;
			sql.parameters[":StartDate"] = startDate;
			sql.parameters[":DueDate"] = dueDate;
			sql.parameters[":OrganizeBox"] = organizeBox;
			sql.parameters[":Source"] = source;
			sql.parameters[":SourceProfileGUID"] = sourceProfileGUID;
			sql.parameters[":LinkGroupGUID"] = linkGroupGUID;
			sql.parameters[":DisplayIndex"] = boxDisplayIndex;
			sql.parameters[":DateArchived"] = dateArchived;
			sql.parameters[":SystemType"] = systemType;
			DB.doSQL(sql);
		}		
		

		public function get Attachments():ArrayCollection
		{
			var AC:ArrayCollection = new ArrayCollection( notes.source.concat( files.source));
			return AC;
		}

		public function divyNotes():void
		{
			// puts first 3 notes into firstNotes, rest into restNotes
			
			firstNotes = new ArrayCollection();
			restNotes = new ArrayCollection();
								
			//var noteCount:int = notes.length -1; //we won't include the "plus" add button here
			var noteCount:int = notes.length;
			var j:int;
				
			for(j=0;j<noteCount;j++){
				if(j<3){
					firstNotes.addItem( notes.getItemAt(j) );
				}
				else{
					restNotes.addItem( notes.getItemAt(j) );
				}
			}			
		}
		
		public function reloadAll(DB:Database):void
		{
			reloadAttachments(DB);
			reloadNotes(DB);
			reloadTags(DB);
		}
		
		public function reloadAttachments(DB:Database):void
		{
			var sql:SQLStatement = new SQLStatement();
	        sql.text = "SELECT attachmentGUID, taskGUID, userGUID, sourcepath, storepath, mailMessageGUID, title " + 
	        		", filetype, sha1digest, isManaged, sourceType, haveData, dateCreated, dateModified " +
	        		"FROM attachment " +
	        		"WHERE taskGUID=:taskGUID ";	        
	        sql.parameters[":taskGUID"] = taskGUID;
	        sql.itemClass = AttachmentVO;
	        
	        DB.doSQL(sql);
	        
			files = new ArrayCollection( sql.getResult().data );
		}
		
		public function reloadNotes(DB:Database):void
		{
			
			var sql:SQLStatement = new SQLStatement();
	        sql.text = "SELECT noteGUID, taskGUID, userGUID, title, content, dateCreated, dateModified " +
	        "FROM note " +
	        "WHERE taskGUID=:taskGUID ";
	        sql.parameters[":taskGUID"] = taskGUID;
	        sql.itemClass = TaskNote;	        
	        DB.doSQL(sql);
	        
	        notes = new ArrayCollection( sql.getResult().data );
		}
		
		public function reloadTags(DB:Database):void
		{
			var sql:SQLStatement = new SQLStatement();
			sql.text = "SELECT t.tagGUID, t.userGUID, t.title, t.dateCreated, t.dateModified " + 
					"FROM tag t, tasktag tt " + 
					"WHERE tt.taskGUID=:TaskGUID AND t.tagGUID=tt.tagGUID " + 
					"ORDER BY title ";
			sql.parameters[":TaskGUID"] = taskGUID;
			sql.itemClass = TagVO;
			DB.doSQL(sql);
			tags = new ArrayCollection( sql.getResult().data );
		}
		
		public function reloadGraphGroupMembers(graphManager:GraphManager):void
		{
			graphGroupMembers = new ArrayCollection( graphManager.getTaskShareUserGroups(taskGUID) );
		}
		
		public function selectForEditing():void
		{
			isSelected=true;
			shouldEdit=true;
		}
		
		public function getSourceProfileTitle(DB:Database):String
		{
			if(Source.NATIVE == source) return "Helium";
		
			if(sourceProfileGUID && "" != sourceProfileGUID){
				var sql:SQLStatement = new SQLStatement();
				sql.text = "SELECT profileName FROM externalprofile " +
					"WHERE profileGUID=:ProfileGUID AND userGUID=:UserGUID";
				sql.parameters[":ProfileGUID"] = sourceProfileGUID;
				sql.parameters[":UserGUID"] = userGUID;
				DB.doSQL(sql);
				var res:SQLResult = sql.getResult();
				if(res.data) return res.data[0].profileName;
			}
			
			return Source.SOURCETITLES[source];
		}

	}
}