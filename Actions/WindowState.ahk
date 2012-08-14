Class CWindowStateAction Extends CAction
{
	static Type := RegisterType(CWindowStateAction, "Change window state")
	static Category := RegisterCategory(CWindowStateAction, "Window")
	static _ImplementsWindowFilter := ImplementWindowFilterInterface(CWindowStateAction)
	static Action := "Maximize"
	static Value := 100
	static ShowState := 0
	Execute(Event)
	{
		hwnd := this.WindowFilterGet()
		WinGet, state, minmax, ahk_id %hwnd%
		if(this.Action = "Maximize")
			WinMaximize("ahk_id " hwnd)
		else if(this.Action = "Minimize")
			WinMinimize("ahk_id " hwnd)
		else if(this.Action = "Restore")
			WinRestore, ahk_id %hwnd%
		else if(this.Action = "Toggle Max/Normal" && state = 1)
			WinRestore, ahk_id %hwnd%
		else if(this.Action = "Toggle Max/Normal")
			WinMaximize("ahk_id " hwnd)
		else if(this.Action = "Toggle Min/Normal" && state = -1)
			WinRestore, ahk_id %hwnd%
		else if(this.Action = "Toggle Min/Normal")
			WinMinimize("ahk_id " hwnd)
		else if(this.Action = "Toggle Min/Max" && state = -1)
			WinMaximize("ahk_id " hwnd)
		else if(this.Action = "Toggle Min/Max")
			WinMinimize("ahk_id " hwnd)
		else if(this.Action = "Toggle Min/Previous state" && state = -1)
			WinActivate, ahk_id %hwnd%
		else if(this.Action = "Toggle Min/Previous state")
			WinMinimize("ahk_id " hwnd)
		else if(this.Action = "Maximize->Normal->Minimize" && state = 1)
			WinRestore, ahk_id %hwnd%
		else if(this.Action = "Maximize->Normal->Minimize" && state = 0)
			WinMinimize("ahk_id " hwnd)
		else if(this.Action = "Minimize->Normal->Maximize" && state = -1)
			WinRestore, ahk_id %hwnd%
		else if(this.Action = "Minimize->Normal->Maximize" && state = 0)
			WinMaximize("ahk_id " hwnd)
		else
		{
			if(this.Action = "Set always on top")
				WinSet, AlwaysOnTop, On, ahk_id %hwnd%
			else if(this.Action = "Disable always on top")
				WinSet, AlwaysOnTop, Off, ahk_id %hwnd%
			else if(this.Action = "Toggle always on top")
				WinSet, AlwaysOnTop, Toggle, ahk_id %hwnd%
			else 
			{
				if(this.Action = "Set Transparency")
				{
					newValue := Event.ExpandPlaceholders(this.Value)
					if(InStr(newValue,"+") = 1||InStr(newValue,"-") = 1||InStr(newValue,"*") = 1||InStr(newValue,"/") = 1)
					{
						operator := SubStr(newValue,1,1)
						newValue := SubStr(newValue,2)
						WinGet, oldValue, Transparent, ahk_id %hwnd%
						if(operator = "+")
							newValue += oldValue
						else if(operator = "-")
							newValue := oldValue - newValue
						else if(operator = "*")
							newValue := oldValue * newValue
						else if(operator = "/")
							newValue := oldValue / newValue
					}
					WinSet, Transparent, %newValue%, ahk_id %hwnd%
				}
				if(this.ShowState)
					Notify("Window state", "Transparency: " newValue , 2, NotifyIcons.Info)
				return 1
			}
			if(this.ShowState)
			{
				WinGet, es, ExStyle, ahk_id %hwnd%
				Notify("Window state", "Always on top: " (es & 0x8 > 0 ? "On" : "Off") , 2, NotifyIcons.Info)
			}
			return 1
		}
		if(this.ShowState)
		{
			WinGet, state, minmax, ahk_id %hwnd%
			if(state = -1)
				String := "Window minimied"
			else if(state = 0)
				String := "Window restored"
			else if(state = 1)
				String := "Window maximized"
			
			Notify("Window state", String , 2, NotifyIcons.Info)
		}
		return 1
	}
	
	DisplayString()
	{
		return this.Action " " this.WindowFilterDisplayString()
	}
	
	GuiShow(GUI,GoToLabel="")
	{
		static sGUI
		if(GoToLabel = "")
		{
			sGUI := GUI
			this.AddControl(GUI, "DropDownList", "Action", "Maximize|Minimize|Restore|Toggle Max/Normal|Toggle Min/Normal|Toggle Min/Max|Toggle Min/Previous state|Maximize->Normal->Minimize|Minimize->Normal->Maximize|Set always on top|Disable always on top|Toggle always on top|Set Transparency", "", "Action:")
			this.AddControl(GUI, "Text", "tmpHint", "The value below is only used for transparency. Prepend +,-,* and / for relative changes.")
			this.AddControl(GUI, "Edit", "Value", "", "", "Value:", "Placeholders", "WindowState_Placeholders")
			this.AddControl(GUI, "Checkbox", "ShowState", "", "", "Show State:")
			this.WindowFilterGuiShow(GUI)
		}
		else if(GoToLabel = "WindowState_Placeholders")
			ShowPlaceholderMenu(sGUI, "Value")
	}
	
	GuiSubmit(GUI)
	{
		this.WindowFilterGUISubmit(GUI)
		Base.GUISubmit(GUI)
	}
}
WindowState_Placeholders:
GetCurrentSubEvent().GuiShow("","WindowState_Placeholders")
return