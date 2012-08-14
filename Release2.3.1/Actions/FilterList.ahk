Class CFilterListAction Extends CAction
{
	static Type := RegisterType(CFilterListAction, "Filter list")
	static Category := RegisterCategory(CFilterListAction, "7plus")
	static Operator := "that end with"
	static List := "${SelNQ}"
	static Filter := ".exe"
	static Separator := "``n"
	static ExitOnEmptyList := true
	static Action := "Keep list entries from"
	Execute(Event)
	{
		key := SubStr(this.List, InStr(this.List, "${") + 2, InStr(this.List, "}",InStr(this.List, "${") + 2) - InStr(this.List, "${") - 2)
		List := Event.ExpandPlaceholders(this.List)
		Filter := Event.ExpandPlaceholders(this.Filter)
		Filter := StringReplace(Filter, "``n", "`n")
		Separator := this.Separator
		array := ToArray(List, Separator, wasQuoted)
		newarray := Array()
		Loop % array.MaxIndex()
		{
			result := (	this.Operator = "that are equal to" && array[A_Index] = Filter
							|| 	this.Operator = "that are greater than" && array[A_Index] > Filter
							|| 	this.Operator = "that are lower than" && array[A_Index] > Filter
							|| 	this.Operator = "that contain" && InStr(array[A_Index], Filter) > 0
							|| 	this.Operator = "that match regular expression" && RegexMatch(array[A_Index], "i)" Filter) > 0
							|| 	this.Operator = "that start with" && InStr(array[A_Index], Filter) = 1
							|| 	this.Operator = "that end with" && strEndsWith(array[A_Index], Filter))
			if((this.Action = "Keep list entries from" && result) || (this.Action = "Remove list entries from" && !result))
				newarray.Insert(array[A_Index])
		}
		
		if(this.ExitOnEmptyList && newarray.MaxIndex() = 0)
			return 0
		newlist := ArrayToList(newarray, Separator, wasQuoted)
		Event.Placeholders[key] := newlist
		return 1
	}
	DisplayString()
	{
		return this.Action " " this.List " " this.Operator " " this.Filter
	}
	GuiShow(GUI, GoToLabel = "")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "Text", "Text", "This action removes list entries from a placeholder.")
			this.AddControl(GUI, "DropDownList", "Action", "Keep list entries from|Remove list entries from","","Action:")
			this.AddControl(GUI, "Edit", "List", "", "", "List:", "Placeholders","Action_FilterList_Placeholders_List")
			this.AddControl(GUI, "DropDownList", "Operator", "that are equal to|that are greater than|that are lower than|that contain|that match regular expression|that start with|that end with","","Operator:")
			this.AddControl(GUI, "Edit", "Filter", "", "", "Filter:", "Placeholders","Action_FilterList_Placeholders_Filter")
			this.AddControl(GUI, "Text", "tmpText", "List separator character. Not needed if list items are quoted. Use ``n for newline separator.")
			this.AddControl(GUI, "Edit", "Separator", "", "", "Separator:")
			this.AddControl(GUI, "Checkbox", "ExitOnEmptyList", "Stop action if all list entries were removed")
		}
		else if(GoToLabel = "Placeholders_List")
			ShowPlaceholderMenu(sGUI, "List")
		else if(GoToLabel = "Placeholders_Filter")
			ShowPlaceholderMenu(sGUI, "Filter")
	}
}
Action_FilterList_Placeholders_List:
GetCurrentSubEvent().GuiShow("","Placeholders_List")
return
Action_FilterList_Placeholders_Filter:
GetCurrentSubEvent().GuiShow("","Placeholders_Filter")
return