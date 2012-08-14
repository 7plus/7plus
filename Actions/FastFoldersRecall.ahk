Class CFastFoldersRecallAction Extends CAction
{
	static Type := RegisterType(CFastFoldersRecallAction, "Open Fast Folder")
	static Category := RegisterCategory(CFastFoldersRecallAction, "Fast Folders")
	static __WikiLink := "FastFoldersRecall"
	static Slot := 0
	
	Execute(Event)
	{
		global FastFolders
		Slot := this.Slot
		if(Slot >= 0 && Slot <= 9 )
			Navigation.SetPath(FastFolders[Slot].Path)
		return 1
	} 

	DisplayString()
	{
		return "Open Fast Folder: " this.Slot
	}
	
	GuiShow(GUI)
	{
		this.AddControl(GUI, "Edit", "Slot", "", "", "Slot (0-9):")
	}

	GuiSubmit(GUI)
	{
		Base.GUISubmit(GUI)
		this.Slot := Clamp(this.Slot, 0, 9)
	}
}
