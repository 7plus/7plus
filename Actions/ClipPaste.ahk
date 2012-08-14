Class CClipPasteAction Extends CAction
{
	static Type := RegisterType(CClipPasteAction, "Paste clipboard entry")
	static Category := RegisterCategory(CClipPasteAction, "System")
	static __WikiLink := "ClipPaste"
	static Index := 0
	
	Execute(Event)
	{
		ClipboardMenuClicked(this.Index)
	} 

	DisplayString()
	{
		return "Paste clipboard history entry"
	}
	
	GuiShow(GUI)
	{
		this.AddControl(GUI, "Edit", "Index", "", "", "Index:")
	}
	
	GuiSubmit(GUI)
	{
		Base.GuiSubmit(GUI)
		return !(this.Index >= 1 && this.Index <= 10)
	}
}
