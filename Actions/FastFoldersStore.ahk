Class CFastFoldersStoreAction Extends CAction
{
	static Type := RegisterType(CFastFoldersStoreAction, "Save Fast Folder")
	static Category := RegisterCategory(CFastFoldersStoreAction, "Fast Folders")
	static __WikiLink := "FastFoldersStore"
	static Slot := 0
	
	Execute(Event)
	{
		if(ApplicationState.IsPortable)
		{
			Notify("Unsupported in portable mode", "7plus is running in portable mode. Features which need to make changes to the registry won't be available.", 5, NotifyIcons.Error)
			return
		}	
		if(!A_IsAdmin)
		{
			Notify("Admin privileges required!", "7plus is running without admin priviledges. Features which need to make changes to the registry won't be available.", 5, NotifyIcons.Error)
			return
		}
		Slot := this.Slot
		Folder := Event.ExpandPlaceholders(this.Folder)
		if(Slot >= 0 && Slot <= 9)
			UpdateStoredFolder(Slot, Folder)
		return 1
	}

	DisplayString()
	{
		return "Store Fast Folder: " this.Slot
	} 
	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI	
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Edit", "Folder", "", "", "Folder:", "Placeholders", "FastFoldersStore_Placeholders")
			this.AddControl(GUI, "Edit", "Slot", "", "", "Slot (0-9):")
		}
		else if(GoToLabel = "Placeholders")
			ShowPlaceholderMenu(sGUI, "Folder")
	}

	GuiSubmit(GUI)
	{
		Base.GuiSubmit(GUI)
		this.Slot := Clamp(this.Slot, 0, 9)
	}
}
FastFoldersStore_Placeholders:
GetCurrentSubEvent().GuiShow("", "Placeholders")
return
