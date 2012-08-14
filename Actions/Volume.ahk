Class CVolumeAction Extends CAction
{
	static Type := RegisterType(CVolumeAction, "Change sound volume")
	static Category := RegisterCategory(CVolumeAction, "System")	
	static Action := "Set Volume"
	static Volume := 100
	static ShowVolume := true

	Execute(Event)
	{
		;Need to check for sign before and after expansion because AHK will swallow the + sign on numeric strings and turn it into a number.
		Current := 0
		if(WinVer >= WIN_Vista)
		{
			if(InStr(this.Volume, "+") = 1 || InStr(this.Volume, "-") = 1)
				Current := VA_GetMasterVolume()
			Volume := Event.ExpandPlaceholders(this.Volume)		
			if(InStr(Volume, "+") = 1 || InStr(Volume, "-") = 1)
				Current := VA_GetMasterVolume()
			if(this.Action = "Mute")
				VA_SetMasterMute(1)
			else if(this.Action = "Unmute")
				VA_SetMasterMute(0)
			else if(this.Action = "Toggle mute/unmute" && VA_GetMasterMute())
				VA_SetMasterMute(0)
			else if(this.Action = "Toggle mute/unmute")
				VA_SetMasterMute(1)
			else
			{
				VA_SetMasterMute(0) ;If setting volume we probably don't want to stay muted.
				VA_SetMasterVolume(Current+Volume)
			}
			if(this.ShowVolume)
			{

				if(!ApplicationState.VolumeNotificationWindow)
					ApplicationState.VolumeNotificationWindow := Notify("Volume","","", VA_GetMasterMute() ? NotifyIcons.SoundMute : NotifyIcons.Sound, "ToggleMute", {min : 0, max : 0, value : VA_GetMasterVolume()})
				Else
					ApplicationState.VolumeNotificationWindow.Progress := VA_GetMasterVolume()
				SetTimer, ClearNotifyID, -1500
			}
		}
		else
		{
			if(InStr(this.Volume, "+") = 1 || InStr(this.Volume, "-") = 1)
				SoundGet, Current
			Volume := Event.ExpandPlaceholders(this.Volume)		
			if(InStr(Volume, "+") = 1 || InStr(Volume, "-") = 1)
				SoundGet, Current
			if(this.Action = "Mute")
				SoundSet, 1,, Mute
			else if(this.Action = "Unmute")
				SoundSet, 0,, Mute
			else if(this.Action = "Toggle mute/unmute" && SoundGet("","Mute"))
				SoundSet, 1,, Mute
			else if(this.Action = "Toggle mute/unmute")
				SoundSet, 0,, Mute
			else
			{
				SoundSet, 0,, Mute ;If setting volume we probably don't want to stay muted.
				SoundSet, % Current + Volume
			}
			if(this.ShowVolume)
			{
				if(!ApplicationState.VolumeNotificationWindow)
					ApplicationState.VolumeNotificationWindow := Notify("Volume","","", SoundGet("", "Mute") ? NotifyIcons.SoundMute : NotifyIcons.Sound, "ToggleMute", {min : 0, max : 0, value : SoundGet("", "Volume")})
				else
					ApplicationState.VolumeNotificationWindow.Progress := SoundGet("", "Volume")
				SetTimer, ClearNotifyID, -1500
			}
		}
		return 1
	}

	DisplayString()
	{
		return this.Action (this.Action = "Set Volume" ? " to " this.Volume : "")
	}

	GuiShow(GUI)
	{
		this.AddControl(GUI, "DropDownList", "Action", "Mute|Unmute|Toggle mute/unmute|Set volume", "", "Action:")
		this.AddControl(GUI, "Text", "tmpText", "Use +/- to increase/decrease volume")
		this.AddControl(GUI, "Edit", "Volume", "", "", "Volume (%):")
		this.AddControl(GUI, "Checkbox", "ShowVolume", "Show Volume")
	}
}

ClearNotifyID:
ApplicationState.VolumeNotificationWindow.Close()
ApplicationState.Remove("VolumeNotificationWindow")
return

ToggleMute()
{
	ApplicationState.Remove("VolumeNotificationWindow")
	if(WinVer >= WIN_VISTA)
	{
		if(VA_GetMasterMute())
			VA_SetMasterMute(0)
		else
			VA_SetMasterMute(1)
	}
	else
	{
		if(SoundGet("","Mute"))
			SoundSet, 1,, Mute
		else
			SoundSet, 0,, Mute
	}
	return
}