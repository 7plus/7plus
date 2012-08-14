Class CDirectoryChangeTrigger Extends CTrigger
{
	static Type := RegisterType(CDirectoryChangeTrigger, "Trigger on file change")
	static Category := RegisterCategory(CDirectoryChangeTrigger, "System")
	static Path := ""
	static Files := ""
	static ChangeType := "All"
	static PlaceholderFile := "File"
	static PlaceholderNewFile := "NewFile"
	Enable(Event)
	{
		;Check for valid filters  and call watchdir with correct params here
		if(this.Path && this.Files)
		{
			Files := this.Files
			StringReplace, Files, Files,  |, |\
			WatchDirectory(this.Path "|" Files, "DirectoryChangeTrigger_ReportChanges")
			Event.OneInstance := true
		}
	}
	Disable()
	{
		;Disable watchdir here, possibly check that there are no other triggers watching the same directory
		;~ Watchdir()
	}
	
	Matches(Filter, Event)
	{
		;Check for correct type
		if(this.ChangeType != "All" && this.ChangeType != Filter.ChangeType)
			return false
		;Check if the involved file matches the files specified here
		Files := ToArray(this.Files, "|")
		Path := (strEndsWith(this.Path, "*") || strEndsWith(this.Path, "\")) ? this.Path : this.Path "\"
		for index,File in Files
		{
			Regex := ConvertFilterStringToRegex(Path File)
			if(RegExMatch(Filter.File, Regex))
			{
				Event.Placeholders[this.PlaceholderFile ? this.PlaceholderFile : "File"] := Filter.File
				if(Filter.ChangeType = "File renamed")
					Event.Placeholders[this.PlaceholderNewFile ? this.PlaceholderNewFile : "NewFile"] := Filter.NewFile
				return true
			}
		}
		return false
	}
	
	DisplayString()
	{
		return "Watch " this.Path ", " this.Files " for changes"
	}

	GuiShow(GUI)
	{
		this.AddControl(GUI, "ComboBox", "ChangeType", "All|File changed|File created|File renamed|File deleted", "", "Watch for:","","","","","The kind of change events this trigger processes.")
		this.AddControl(GUI, "Edit", "Path", "", "", "Path:","","","","","The path of the involved directory. You can add a * at the end to include subdirectories.")
		this.AddControl(GUI, "Edit", "Files", "", "", "Files:","","","","","The files which are handled by this trigger. You can use * and ? wildcards. Separate multiple file filters with |.")
		this.AddControl(GUI, "Edit", "PlaceholderFile", "", "", "Placeholder file:","","","","","The path to the changed file can be accessed through this placeholder, but only by the conditions and actions from this event. Just the name, no ${} around it.")
		this.AddControl(GUI, "Edit", "PlaceholderNewFile", "", "", "Placeholder new file:","","","","","The path to the new filename when a file was renamed. Can only be used by conditions and actions from this event. Just the name, no ${} around it.")
	}
}

;Called when a file monitored by one of this triggers is changed
DirectoryChangeTrigger_ReportChanges(from,to)
{
	DirectoryChangeTrigger := new CDirectoryChangeTrigger()
	if(from && from = to)
	{
		DirectoryChangeTrigger.ChangeType := "File changed"
		DirectoryChangeTrigger.File := from
	}
	else if(from && to)
	{
		DirectoryChangeTrigger.ChangeType := "File renamed"
		DirectoryChangeTrigger.File := from
		DirectoryChangeTrigger.NewFile := to
	}
	else if(from && !to)
	{
		DirectoryChangeTrigger.ChangeType := "File deleted"
		DirectoryChangeTrigger.File := from
	}
	else if(!from && to)
	{
		DirectoryChangeTrigger.ChangeType := "File created"
		DirectoryChangeTrigger.File := to
	}
	EventSystem.OnTrigger(DirectoryChangeTrigger)
}