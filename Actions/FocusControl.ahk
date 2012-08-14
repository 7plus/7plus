Class CFocusControlAction Extends CAction
{
	static Type := RegisterType(CFocusControlAction, "Focus a control")
	static Category := RegisterCategory(CFocusControlAction, "Window")
	static __WikiLink := "FocusControl"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CFocusControlAction)
	static TargetControl := "Edit1"
	Execute(Event)
	{
		hwnd := this.WindowFilterGet()
		TargetControl := this.TargetControl
		if(IsNumeric(TargetControl))
			ControlFocus, ,ahk_id %TargetControl%
		else
			ControlFocus, %TargetControl%, ahk_id %hwnd%
		return 1
	}
	DisplayString()
	{
		return "Focus " this.TargetControl ", " this.WindowFilterDisplayString()
	}
	GuiShow(GUI)
	{
		this.AddControl(GUI, "Text", "Desc", "This action can set the keyboard focus to a control .")
		this.WindowFilterGuiShow(GUI)
		this.AddControl(GUI, "Text", "tmpText", "Enter a window handle, a ClassNN (e.g. ""Edit1""), or text of the control here.")
		this.AddControl(GUI, "Edit", "TargetControl", "", "", "Target Control:")
	}

	GuiSubmit(GUI)
	{
		this.WindowFilterGuiSubmit(GUI)
		Base.GUISubmit(GUI)
	}
}
