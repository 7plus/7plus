Class CTimerTrigger Extends CTrigger
{
	static Type := RegisterType(CTimerTrigger, "Timer")
	static Category := RegisterCategory(CTimerTrigger, "System")
	static __WikiLink := "Timer"
	static Time := ""
	static Text := ""
	static ShowProgress := 0
	static Restart := 0

	Enable(Event)
	{
		if(!this.tmpStart)
			this.Start()
		if(this.ShowProgress)
		{
			if(!this.tmpGUINum)
			{
				GUINum := GetFreeGuiNum(10)
				if(GUINum)
				{
					this.tmpGUINum := GUINum
					Gui, %GUINum%:Add, Text, hwndEventName w200,% this.Text ? this.Text : Event.Name
					Gui, %GUINum%:Add, Progress, hwndProgress w200 -Smooth, 100
					GUI, %GUINum%:Add, Text, hwndText w200, Time left:
					GUI, %GUINum%:Add, Button, hwndStartPause gTimer_StartPause y4 w100, Pause
					GUI, %GUINum%:Add, Button, hwndStop gTimer_Stop y+4 w100, Stop
					GUI, %GUINum%:Add, Button, hwndReset gTimer_Reset y+4 w100, Reset
					GUI, %GUINum%:+AlwaysOnTop -SysMenu -Resize
					Sleep 10
					GUI, %GUINum%:Show,,Timer
					this.tmpProgress := Progress
					this.tmpText := Text
					this.tmpStartPause := StartPause
					this.tmpStop := Stop
					this.tmpResetHandle := Reset
					this.tmpEventName := EventName
					SetTimer, UpdateTimerProgress, 1000
				}
			}
		}
	}
	PrepareCopy(Event)
	{
		Event.Trigger.tmpState := Event.Enabled
	}
	PrepareReplacement(Original, Copy)
	{
		if(Copy.Trigger.Is(CTimerTrigger))
		{
			Copy.Trigger.tmpIsPaused := Original.Trigger.tmpIsPaused
			Copy.Trigger.tmpStart := Original.Trigger.tmpStart
			Copy.Trigger.tmpStartNice := Original.Trigger.tmpStartNice
			Copy.Trigger.tmpProgress := Original.Trigger.tmpProgress
			Copy.Trigger.tmpText := Original.Trigger.tmpText
			Copy.Trigger.tmpStartPause := Original.Trigger.tmpStartPause
			Copy.Trigger.tmpStop := Original.Trigger.tmpStop
			Copy.Trigger.tmpResetHandle := Original.Trigger.tmpResetHandle
			Copy.Trigger.tmpGUINum := Original.Trigger.tmpGUINum
			Copy.Trigger.tmpReset := Original.Trigger.tmpReset
			Copy.Trigger.tmpEventName := Original.Trigger.tmpEventName
		}
		else
		{
			Original.Trigger.Stop(Original)
		}
	}
	StartPause()
	{
		if(this.tmpIsPaused)
			this.Start()
		else
			this.Pause()
	}
	Start()
	{
		if(!this.tmpIsPaused)
		{
			this.tmpStart := A_TickCount
			this.tmpStartNice := A_Now
		}
		else
		{
			this.tmpStart := A_TickCount - this.tmpIsPaused ;Also stores time that passed already
			nicetime := A_Now
			nicetime += -this.tmpIsPaused * 1000, seconds
			this.tmpStartNice := nicetime
		}
		this.tmpIsPaused := false
		if(this.ShowProgress && this.tmpGUINum)
		{
			hwndStartPause := this.tmpStartPause
			if(!this.tmpReset)
				ControlSetText,,Pause, ahk_id %hwndStartPause%
		}
	}
	Pause()
	{
		if(this.ShowProgress && this.tmpGUINum)
		{
			hwndStartPause := this.tmpStartPause
			if(!this.tmpReset)
				ControlSetText,,Start, ahk_id %hwndStartPause%
		}
		if(!this.tmpIsPaused)
			this.tmpIsPaused := A_TickCount - this.tmpStart
	}
	Stop(Event)
	{
		Event.SetEnabled(false)
		Event.Trigger.Disable(Event)
	}
	Reset()
	{
		this.tmpReset := 1
		if(this.tmpIsPaused)
			this.tmpIsPaused := 0.001 ;one millisecond shouldn't be too bad :)
		this.tmpStart := A_TickCount
		this.tmpStartNice := A_Now
	}
	Disable(Event)
	{
		if(Event.enabled) ;Avoid disabling timers when applying settings, unless real disable is desired
			return
		this.tmpStart := ""
		this.tmpStartNice := ""
		this.tmpIsPaused := 0
		if(this.ShowProgress)
		{
			GUINum := this.tmpGUINum
			if(GUINum)
			{
				this.Remove("tmpGUINum")
				this.Remove("tmpProgress")
				this.Remove("tmpText")
				this.Remove("tmpEventName")
				GUI, %GUINum%:Destroy
			}
		}
	}
	Delete(Event)
	{
		Event.Disable()
	}
	;Called every second to check if time has run out yet
	Matches(Filter, Event)
	{
		if(this.tmpStart && !this.tmpIsPaused && A_TickCount > (this.tmpStart + this.Time))
		{
			if(this.Restart)
			{
				this.tmpStart := 0
				this.Enable(Event)
			}
			else
			{
				Event.SetEnabled(false)
				Event.Trigger.Disable(Event)
			}
			return true
		}
		return false
	}

	DisplayString()
	{
		hours := Floor(this.Time / 1000 / 3600)
		minutes := Floor((this.Time / 1000 - hours * 3600)/60)
		seconds := Floor((this.Time / 1000 - hours * 3600 - minutes * 60))
		start := this.tmpStartNice
		FormatTime, start, start, Time
		return "Timer - Trigger in " (strLen(hours) = 1 ? "0" hours : hours) ":" (strLen(minutes) = 1 ? "0" minutes : minutes) ":" (strLen(seconds) = 1 ? "0" seconds : seconds)
	}

	GuiShow(GUI)
	{
		this.AddControl(GUI, "Text", "Desc", "This trigger represents a timer that will execute this event when the timer runs out.")
		hours := Floor(this.Time / 1000 / 3600)
		minutes := Floor((this.Time / 1000 - hours * 3600)/60)
		seconds := Floor((this.Time / 1000 - hours * 3600 - minutes * 60))
		this.tmpTime := (strLen(hours) = 1 ? "0" hours : hours) (strLen(minutes) = 1 ? "0" minutes : minutes) (strLen(seconds) = 1 ? "0" seconds : seconds)
		this.AddControl(GUI, "Time", "tmpTime", "", "", "Start in:")
		this.AddControl(GUI, "Checkbox", "ShowProgress", "Show remaining time", "", "")
		this.AddControl(GUI, "Checkbox", "Restart", "Restart timer on zero", "", "","","","","","If set, the event will execute when the time runs out and the timer will start again.")
		this.AddControl(GUI, "Edit", "Text", "", "", "Window text:")
	}

	GuiSubmit(GUI)
	{
		this.SubmitControls(GUI)
		hours := SubStr(this.tmptime, 1, 2)
		minutes := SubStr(this.tmptime, 3, 2)
		seconds := SubStr(this.tmptime, 5, 2)
		this.Time := (hours * 3600 + minutes * 60 + seconds) * 1000
	} 
}
Timer_StartPause:
TimerEventFromGUINumber().Trigger.StartPause()
return
Timer_Stop:
TimerEventFromGUINumber().Trigger.Stop(TimerEventFromGUINumber())
return
Timer_Reset:
TimerEventFromGUINumber().Trigger.Reset()
return
TimerEventFromGUINumber()
{
	for index, Event in EventSystem.Events
		if(Event.Trigger.Is(CTimerTrigger) && Event.Trigger.tmpGUINum = A_GUI)
			return Event
	for index, TemporaryEvent in EventSystem.TemporaryEvents
		if(TemporaryEvent.Trigger.Is(CTimerTrigger) && TemporaryEvent.Trigger.tmpGUINum = A_GUI)
			return TemporaryEvent
	return 0
}

;Called once a second to update the progress on all timer windows and trigger the timers whose time has come
UpdateTimerProgress:
UpdateTimerProgress()
EventSystem.OnTrigger(new CTimerTrigger())
return

UpdateTimerProgress()
{
	for index, Event in EventSystem.Events
		GoSub UpdateTimerProgress_InnerLoop
	for index, Event in EventSystem.TemporaryEvents
		GoSub UpdateTimerProgress_InnerLoop
	return
	
	UpdateTimerProgress_InnerLoop:
	if(Event.Trigger.Is(CTimerTrigger)) ;Update all timers
	{
		timer := Event.Trigger
		if(Event.Enabled && (!timer.tmpIsPaused || timer.tmpReset) && timer.ShowProgress && timer.tmpGUINum)
		{
			GUINum := timer.tmpGUINum
			progress := Round(100 - (A_TickCount - timer.tmpStart)/timer.Time * 100)
			hours := max(Floor((timer.Time - (A_TickCount - timer.tmpStart)) / 1000 / 3600),0)
			minutes := max(Floor(((timer.Time - (A_TickCount - timer.tmpStart)) / 1000 - hours * 3600)/60),0)
			seconds := max(Floor(((timer.Time - (A_TickCount - timer.tmpStart)) / 1000 - hours * 3600 - minutes * 60))+1,0)
			Time := "Time left: " (strLen(hours) = 1 ? "0" hours : hours) ":" (strLen(minutes) = 1 ? "0" minutes : minutes) ":" (strLen(seconds) = 1 ? "0" seconds : seconds)
			hwndProgress := timer.tmpProgress
			SendMessage, 0x402, progress,0,, ahk_id %hwndProgress%
			hwndtext := timer.tmpText
			ControlSetText,,%Time%, ahk_id %hwndtext%
			hwndEventName := timer.tmpEventName
			timer.tmpReset := 0
		}
	}
	return
}