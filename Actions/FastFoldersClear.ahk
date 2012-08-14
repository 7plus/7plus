Class CFastFoldersClearAction Extends CAction
{
	static Type := RegisterType(CFastFoldersClearAction, "Clear Fast Folder")
	static Category := RegisterCategory(CFastFoldersClearAction, "Fast Folders")
	static __WikiLink := "FastFoldersClear"
	static Slot := 0
	
	Execute(Event)
	{
		if(ApplicationState.IsPortable)
		{
			Notify("Unsupported in portable mode", "7plus is running in portable mode. Features which need to make changes to the registry won't be available.", 5, NotifyIcons.Error)
			return 0
		}
		if(!A_IsAdmin)
		{
			Notify("Admin privileges required!", "7plus is running without admin priviledges. Features which need to make changes to the registry won't be available.", 5, NotifyIcons.Error)
			return 0
		}
		Slot := this.Slot
		if(Slot >= 0 && Slot <= 9 )
			ClearStoredFolder(Slot)
		return 1
	} 

	DisplayString()
	{
		return "Clear Fast Folder: " this.Slot
	} 
	
	GuiShow(GUI)
	{
		this.AddControl(GUI, "Edit", "Slot", "", "", "Slot (0-9):")
	}

	GuiSubmit(GUI)
	{
		Base.GuiSubmit(GUI)
		this.Slot := Clamp(this.Slot, 0, 9)
	}
}
