Class CMouseOverCondition Extends CCondition
{
	static Type := RegisterType(CMouseOverCondition, "Mouse over")
	static Category := RegisterCategory(CMouseOverCondition, "Mouse")
	static MouseOverType := "Window"
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CMouseOverCondition)
	Evaluate()
	{
		if(this.MouseOverType = "Window")
		{
			MouseGetPos,,,window
			return this.WindowFilterMatches(window)
		}
		else if(this.MouseOverType = "Clock")
			return IsMouseOverClock()
		else
		{
			result := MouseHitTest()
			if(this.MouseOverType = "TitleBar")
				return result = 2
			else if(this.MouseOverType = "MinimizeButton")
				return result = 8
			else if(this.MouseOverType = "MaximizeButton")
				return result = 9
			else if(this.MouseOverType = "CloseButton")
				return result = 20
		}
	}
	DisplayString()
	{
		if(this.MouseOverType = "Window")
			return "Mouse over: " this.WindowFilterDisplayString()
		else
			return "Mouse over: " this.MouseOverType
	}

	GuiShow(GUI,GoToLabel="")
	{
		if(GoToLabel = "")
		{
			this.tmpGUI := GUI
			this.tmpPreviousSelection := ""
			this.AddControl(GUI, "DropDownList", "MouseOverType", "Clock|Window|Titlebar|MinimizeButton|MaximizeButton|CloseButton", "MouseOver_SelectionChange", "Mouse Over:")
			this.GuiShow("","MouseOver_SelectionChange")
		}
		else if(GoToLabel = "MouseOver_SelectionChange")
		{
			DropDown_MouseOverType := this.tmpGUI.DropDown_MouseOverType
			ControlGetText, MouseOverType, , ahk_id %DropDown_MouseOverType%
			if(MouseOverType = "Window")
			{
				if(MouseOverType != this.tmpPreviousSelection)
				{
					if(this.tmpPreviousSelection)
						ImplementWindowFilterInterface(this) ;Reset to default values
					this.WindowFilterGuiShow(this.tmpGUI)
				}
			}
			else
			{
				this.WindowFilterGuiSubmit(this.tmpGUI)
				if(this.tmpPreviousSelection = "Window")
					this.tmpGUI.y := this.tmpGUI.y - 60
			}
			this.tmpPreviousSelection := MouseOverType
		}
	}
	GuiSubmit(GUI)
	{
		this.Remove("tmpGUI")
		this.Remove("tmpPreviousSelection")
		this.WindowFilterGuiSubmit(GUI)
		Base.GuiSubmit(GUI)
	}
}
MouseOver_SelectionChange:
GetCurrentSubEvent().GuiShow("","MouseOver_SelectionChange")
return