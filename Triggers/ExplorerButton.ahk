Class CExplorerButtonTrigger Extends CTrigger
{
	static Type := RegisterType(CExplorerButtonTrigger, "Explorer bar button")
	static Category := RegisterCategory(CExplorerButtonTrigger, "Explorer")
	static Name := "ExplorerButton"
	static Tooltip := "ExplorerButton"
	static ShowSelected := true
	static ShowNoSelected := true

	Enable(Event)
	{
		if(!ApplicationState.IsPortable && A_IsAdmin && WinVer >= WIN_Vista && !FindButton("IsExplorerButton", Event))
			AddButton("", "", Event.ID, this.Name, this.Tooltip, (this.ShowSelected && this.ShowNoSelected ? "Both" : this.ShowSelected ? "Selected" : this.ShowNoSelected ? "NoSelected" : "")) ;Event.ID here
	}
	
	Disable(Event)
	{
		if(!Event.Enabled && A_IsAdmin && WinVer >= WIN_Vista && !ApplicationState.IsPortable)
			RemoveButton("IsExplorerButton", Event)
	}
	
	Delete(Event)
	{
		if(!ApplicationState.IsPortable && WinVer >= WIN_Vista && A_IsAdmin)
			RemoveButton("IsExplorerButton", Event)
	}
	
	;Called when settings are applied. This function checks for changes in the button and possibly recreates it.
	PrepareReplacement(Event1, Event2)
	{
		if(this.Name = Event2.Trigger.Name && this.Tooltip = Event2.Trigger.Tooltip && this.ShowSelected = Event2.Trigger.ShowSelected && this.ShowNoSelected = Event2.Trigger.ShowNoSelected)
			return
		
		;something changed, so lets remove the button. It is later recreated in CExplorerButtonTrigger.Enable()
		if(!ApplicationState.IsPortable && WinVer >= WIN_Vista && A_IsAdmin)
			RemoveButton("IsExplorerButton", Event1)
	}

	Matches(Filter, Event)
	{
		return false ; Match is handled through type trigger in Eventsystem.ahk already
	}

	DisplayString()
	{
		return "Explorer Button " this.Name
	}

	GuiShow(GUI)
	{
		if(WinVer >= WIN_Vista)
		{
			this.AddControl(GUI, "Text", "Desc", "This button will show up in the explorer folder band bar at the top (Vista/7 only)")
			this.AddControl(GUI, "Edit", "Name", this.Name, "", "Button Name:")
			this.AddControl(GUI, "Checkbox", "ShowSelected", "Show when files are selected", "", "")
			this.AddControl(GUI, "Button", "RemoveAllButtons", "Remove custom Explorer Buttons", "RemoveAllExplorerButtons", "")
		}
		else
			this.AddControl(GUI, "Text", "tmpText", "This trigger is only supported in Windows 7 and Vista", "", "")		
	}
}
RemoveAllExplorerButtons:
RemoveAllExplorerButtons()
return
IsExplorerButton(value, key, Event)
{
	if(!Event.Trigger.ShowSelected && InStr(key, "TasksItemsSelected"))
		return false
	else if(!Event.Trigger.ShowNoSelected && InStr(key, "TasksNoItemsSelected"))
		return false
	RegRead, command, HKLM, %key%
	RegexMatch(command,""" -id:(\d+)$", command)
	if(command1 && command1 = Event.ID)
		return true
	return false
}