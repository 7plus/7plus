
ImplementIfInterface(SubEvent)
{
	SubEvent.Operator := "equals"
	SubEvent.Compare := "${P}"
	SubEvent.With := ""
	if(SubEvent.HasKey("__Class"))
	{
		SubEvent.IfEvaluate := Func("If_Evaluate")
		SubEvent.IfDisplayString := Func("If_DisplayString")
		SubEvent.IfGuiShow := Func("If_GuiShow")
		SubEvent.IfGuiSubmit := Func("If_GuiSubmit")
	}
}
If_Evaluate(SubEvent, Event)
{
	Compare := Event.ExpandPlaceholders(SubEvent.Compare)
	With := Event.ExpandPlaceholders(SubEvent.With)
	if(SubEvent.Operator = "equals")
		return Compare = With
	else if(SubEvent.Operator = "is greater than")
		return Compare > With
	else if(SubEvent.Operator = "is lower than")
		return Compare < With
	else if(SubEvent.Operator = "contains")
		return InStr(Compare, With) > 0
	else if(SubEvent.Operator = "matches regular expression")
		return RegexMatch(Compare, With) > 0
	else if(SubEvent.Operator = "starts with")
		return InStr(Compare, With) = 1
	else if(SubEvent.Operator = "ends with")
		return strEndsWith(Compare, With)
}
If_DisplayString(SubEvent)
{
	return "If " SubEvent.Compare " " SubEvent.Operator " " SubEvent.With
}
If_GuiShow(SubEvent, GUI = "", GoToLabel = "")
{
	if(GoToLabel = "")
	{
		SubEvent.tmpIfGUI := GUI
		SubEvent.AddControl(GUI, "Text", "IfDesc", "This is a standard if condition that can evaluate all kinds of relations by comparing placeholders with values.")
		SubEvent.AddControl(GUI, "Edit", "Compare", "", "", "Compare:", "Placeholders", "If_Placeholders_Compare")
		SubEvent.AddControl(GUI, "DropDownList", "Operator", "equals|is greater than|is lower than|contains|matches regular expression|starts with|ends with", "", "Operator")
		SubEvent.AddControl(GUI, "Edit", "With", "", "", "With:", "Placeholders", "If_Placeholders_With")
	}
	else if(GoToLabel = "Placeholders_Compare")
		ShowPlaceholderMenu(SubEvent.tmpIfGUI, "Compare")
	else if(GoToLabel = "Placeholders_With")
		ShowPlaceholderMenu(SubEvent.tmpIfGUI, "With")
}
If_GuiSubmit(SubEvent, GUI)
{
	SubEvent.Remove("tmpIfGUI")
}
If_Placeholders_Compare:
GetCurrentSubEvent().IfGuiShow("","Placeholders_Compare")
return
If_Placeholders_With:
GetCurrentSubEvent().IfGuiShow("","Placeholders_With")
return