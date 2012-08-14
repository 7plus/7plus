Class CIsDialogCondition Extends CCondition
{
	static Type := RegisterType(CIsDialogCondition, "Window is file dialog")
	static Category := RegisterCategory(CIsDialogCondition, "Window")
	static __WikiLink := "IsDialog"
	static ListViewOnly := True
	Evaluate()
	{
		return IsDialog(WinExist("A"), this.ListViewOnly) > 0
	}
	DisplayString()
	{
		return "If file dialog window is active"
	}
	GuiShow(GUI)
	{
		this.AddControl(GUI, "Checkbox", "ListViewOnly", "Check for correct ListView control only")
	}
}
