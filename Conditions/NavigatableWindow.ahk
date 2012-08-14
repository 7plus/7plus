Class CNavigatableWindowCondition Extends CCondition
{
	static Type := RegisterType(CNavigatableWindowCondition, "Can Window be Navigated")
	static Category := RegisterCategory(CNavigatableWindowCondition, "Window")
	static FeatureType := "SetPath"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CNavigatableWindowCondition)

	Evaluate()
	{
		hwnd := this.WindowFilterGet()
		return Navigation.FindNavigationSource(hwnd, this.FeatureType)
	}

	DisplayString()
	{
		return "Test if this window can " this.FeatureType ": " this.WindowFilterDisplayString()
	}

	GuiShow(GUI, GoToLabel = "")
	{
		this.AddControl(GUI, "DropDownList", "FeatureType", "SetPath|GetPath|SelectFiles|GetDisplayName|GetSelectedFilepaths|GetSelectedFilenames|GetFocusedFilename|GetFocusedFilePath|Refresh|GoBack|GoForward|GoUpward", "", "Feature:")
		this.WindowFilterGuiShow(GUI)
	}

	GuiSubmit(GUI)
	{
		this.WindowFilterGuiSubmit(GUI)
		Base.GuiSubmit(GUI)
	}
}