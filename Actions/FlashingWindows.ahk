Class CFlashingWindowsAction Extends CAction
{
	static Type := RegisterType(CFlashingWindowsAction, "Flashing windows")
	static Category := RegisterCategory(CFlashingWindowsAction, "Window")
	static __WikiLink := "FlashingWindows"
	static FlashingWindows := 1 ;Activate flashing windows from taskbar
	static ToggleWindows := 1 ;Toggle between current and last window
	static Notifications := 1 ;Activate notification windows

	Execute(Event)
	{
		FlashingWindows(this)
		return 1
	}

	DisplayString()
	{
		return "Activate notification/flashing/previous window"
	}

	GuiShow(ActionGUI)
	{
		this.AddControl(ActionGUI, "Checkbox", "FlashingWindows", "Activate flashing windows")
		this.AddControl(ActionGUI, "Checkbox", "Notifications", "Activate notification windows")
		this.AddControl(ActionGUI, "Checkbox", "ToggleWindows", "Toggle between previous and active window")
	}
}

FlashingWindows(Action)
{
	global BlinkingWindows, PreviousWindow
	CoordMode, Mouse, Screen
	if(Action.Notifications && z := FindWindow("", "", 0x16CF0000, 0x00000188, "trillian.exe")) ;Trillian isn't needed usually, but if tabs are used, clicking the window is preferred
	{
		WinGetPos x, y, w, h, ahk_id %z%
		x += w / 2
		y += 5
		outputdebug click trillian %x% %y%
		MouseGetPos, mx, my
		ControlClick, , ahk_id %z%
		MouseMove %mx%, %my%, 0
		return 1
	}
	else if (Action.FlashingWindows && BlinkingWindows.MaxIndex() > 0 && WinExist("ahk_id " BlinkingWindows[1]))
	{
		z := BlinkingWindows[1]
		WinActivate ahk_id %z%
		class := WInGetClass("ahk_id " z)
		outputdebug flashingwindows found class %class%
		return 1
	}
	else if(Action.Notifications && z := FindWindow("", "OpWindow", 0x96000000, 0x88))
	{
		WinGetPos x, y, w, h, ahk_id %z%
		outputdebug click opera
		MouseGetPos, mx, my
		ControlClick, , ahk_id %z% ;for some reason clicking the notification window isn't enough, so we manually activate opera window
		MouseMove %mx%, %my%, 0
		z := FindWindow("", "OpWindow", "", 0x00000110)
		WinActivate ahk_id %z%
		return 1
	}
	else if(Action.Notifications && z := FindWindow("", "MozillaUIWindowClass", 0x94000000, 0x88))
	{
		WinGetPos x, y, w, h, ahk_id %z%
		x += w / 2
		y += h / 2
		outputdebug click firefox/thunderbird %x% %y% %w% %h%
		MouseGetPos, mx, my
		ControlClick, , ahk_id %z%
		MouseMove %mx%, %my%, 0
		return 1
	}	
	else if(Action.Notifications && z := FindWindow("", "", 0x96000000, 0x00000088, "Steam.exe"))
	{
		WinGetPos x, y, w, h, ahk_id %z%
		x += w / 2
		y += h / 2
		outputdebug click steam %x% %y%
		MouseGetPos, mx, my
		Click %x% %y%
		MouseMove %mx%, %my%, 0
		return 1
	}
	else if(Action.Notifications && z := FindWindow("TTrayAlert"))
	{
		WinGetPos x, y, w, h, ahk_id %z%
		x += w / 2
		y += h / 2
		outputdebug click skype %x% %y%
		MouseGetPos, mx, my
		Click %x% %y%
		MouseMove %mx%, %my%, 0
		return 1
	}
	else if(Action.Notifications && z := FindWindow("", "tooltips_class32", 0x940001C2, ""))
	{
		WinGetPos x, y, w, h, ahk_id %z%
		x += w / 2
		y += h / 2
		outputdebug click tooltip %x% %y%
		MouseGetPos, mx, my
		Click %x% %y%
		MouseMove %mx%, %my%, 0
		return 1
	}
	else if(Action.ToggleWindows)
	{
		WinActivate ahk_id %PreviousWindow%
		return 1
	}
	return 0
}
