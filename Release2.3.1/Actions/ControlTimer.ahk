Class CControlTimerAction Extends CAction
{
	static Type := RegisterType(CControlTimerAction, "Control timer")
	static Category := RegisterCategory(CControlTimerAction, "7plus")
	static Action := "Start timer"
	static TimerID := ""
	static Time := ""

	Execute(ThisEvent)
	{
		Event := EventSystem.Events.GetEventWithValue("ID", ThisEvent.ExpandPlaceholders(this.TimerID))
		if(this.Action = "Start timer" && (!Event.Trigger.tmpStart || Event.Trigger.tmpIsPaused))
		{
			Event.Enable()
			Event.Trigger.Start()
		}
		else if(this.Action = "Stop timer")
			Event.Trigger.Stop(Event)
		else if(this.Action = "Pause timer")
			Event.Trigger.Pause()
		else if(this.Action = "Start/Pause timer")
			Event.Trigger.StartPause()
		else if(this.Action = "Reset timer")
			Event.Trigger.Reset()
		else if(this.Action = "Set time")
		{
			Time := ThisEvent.ExpandPlaceholders(this.Time)
			if(RegExMatch(Time, "\d\d\:\d\d\:\d\d"))
			{
				hours := SubStr(Time, 1, 2)
				minutes := SubStr(Time, 4, 2)
				seconds := SubStr(Time, 7, 2)
				Event.Trigger.Time := (hours * 3600 + minutes * 60 + seconds) * 1000
			}
			else
				Notify("Timer: Invalid Format", "Control Timer: " Time ": Wrong time format! Format needs to be HH:MM:SS. A placeholder from an input action with Datatype=Time can also be used.", 5, NotifyIcons.Error)
		}
		return 1
	} 

	DisplayString()
	{
		return this.Action ": " this.TimerID ": " (this.TimerID >= 0 ? SettingsWindow.Events.GetItemWithValue("ID", this.TimerID).Name : this.TimerID)
	}

	GuiShow(GUI, GoToLabel = "")
	{
		if(GoToLabel = "")
		{
			this.tmpGUI := GUI
			this.tmpPreviousSelection := ""
			this.AddControl(GUI, "Text", "Desc", "This action controls the behavior of timer (windows).")
			this.AddControl(GUI, "DropDownList", "Action", "Set time|Start timer|Stop timer|Pause timer|Start/Pause timer|Reset timer", "Action_ControlTimer_SelectionChange", "Action:")
			this.AddControl(GUI, "ComboBox", "TimerID", "TriggerType:Timer", "", "Timer:","","","","","The id of the timer event.")
			this.GuiShow("", "ControlTimer_SelectionChange")
		}
		else if(GoToLabel = "ControlTimer_SelectionChange")
		{
			ControlGetText, Action, , % "ahk_id " this.tmpGUI.DropDown_Action
			if(Action = "Set time")
			{
				if(Action != this.tmpPreviousSelection)
				{
					this.AddControl(this.tmpGUI, "Text", "Text1", "Time format: HH:MM:SS.")
					this.AddControl(this.tmpGUI, "Text", "Text2", "A placeholder from an input action with time format may be used.")
					this.AddControl(this.tmpGUI, "Edit", "Time", "", "", "Time:", "Placeholders", "Action_ControlTimer_Placeholder")
				}
			}
			else
			{
				Desc_Time := this.tmpGUI.Desc_Time
				Edit_Time := this.tmpGUI.Edit_Time
				Button1_Time := this.tmpGUI.Button1_Time
								
				ControlGetText, Time, , % "ahk_id " this.tmpGUI.Edit_Time
				this.Time := Time
				
				WinKill, % "ahk_id " this.tmpGUI.Desc_Time
				WinKill, % "ahk_id " this.tmpGUI.Edit_Time
				WinKill, % "ahk_id " this.tmpGUI.Button1_Time
				WinKill, % "ahk_id " this.tmpGUI.Text_Text1
				WinKill, % "ahk_id " this.tmpGUI.Text_Text2
				if(this.tmpPreviousSelection = "Set time")
					this.tmpGUI.y := this.tmpGUI.y - 70
			}
			this.tmpPreviousSelection := Action
		}
		else if(GoToLabel = "Placeholder_Time")
			ShowPlaceholderMenu(this.tmpGUI, "Time")
		else if(GoToLabel = "Placeholder_Timer")
			ShowPlaceholderMenu(this.tmpGUI, "TimerID")
	}
	GuiSubmit(GUI)
	{
		this.Remove("tmpGUI")
		this.Remove("tmpPreviousSelection")
		Base.GuiSubmit(GUI)
	}
}
Action_ControlTimer_SelectionChange:
GetCurrentSubEvent().GuiShow("", "ControlTimer_SelectionChange")
return
Action_ControlTimer_Placeholder:
GetCurrentSubEvent().GuiShow("", "Placeholder_Time")
return