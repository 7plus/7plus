Class CIsFullScreenCondition Extends CCondition
{
	static Type := RegisterType(CIsFullScreenCondition, "Fullscreen window active")
	static Category := RegisterCategory(CIsFullScreenCondition, "Window")
	static UseIncludeList := 1
	static UseExcludeList := 1
	Evaluate()
	{
		return IsFullScreen("A",this.UseExcludeList, this.UseIncludeList)
	}
	DisplayString()
	{
		return "In fullscreen"
	}
	GuiShow(GUI)
	{
		this.AddControl(GUI, "Text", "Desc", "This condition checks if a fullscreen window is active (such as a game or a movie).")
		this.AddControl(GUI, "Checkbox", "UseIncludeList", "Use include list","","","","","","","The include list is specified in Misc settings. All window classes on this list are always recognized as fullscreen.")
		this.AddControl(GUI, "Checkbox", "UseExcludeList", "Use exclude list","","","","","","","The exclude list is specified in Misc settings. All window classes on this list are never recognized as fullscreen.")
	}
}