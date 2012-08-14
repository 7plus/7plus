;Assigns a hotkey to a specific control. It will only trigger the desired label/function/method while the object is focused.
AssignHotkeyToControl(hwnd="", key="", LabelOrDelegate="")
{
	static Hotkeys = []
	if(hwnd = "" && LabelOrDelegate = "")
	{
		guiThreadInfoSize := 8 + 6 * A_PtrSize + 16
		VarSetCapacity(guiThreadInfo, guiThreadInfoSize, 0) 
		NumPut(GuiThreadInfoSize, GuiThreadInfo, 0)
		if(DllCall("GetGUIThreadInfo", "UInt", 0, "PTR", &guiThreadInfo) = 0)
		  return 0
		focusedHwnd := NumGet(guiThreadInfo,8+A_PtrSize, "Ptr")
		if(key)
			return IsLabel(Hotkeys[key][focusedHwnd]) || (IsObject(Hotkeys[key][focusedHwnd]) && Hotkeys[key][focusedHwnd].__Class = "Delegate")
		else if(IsLabel(Hotkeys[A_ThisHotkey][focusedHwnd]))
			GoSub % Hotkeys[A_ThisHotkey][focusedHwnd]
		else if(IsObject(Hotkeys[A_ThisHotkey][focusedHwnd]) && Hotkeys[A_ThisHotkey][focusedHwnd].__Class = "Delegate")
			Hotkeys[A_ThisHotkey][focusedHwnd].()
	}
	else if(WinExist("ahk_id " hwnd) && IsLabel(LabelOrDelegate) || (IsObject(LabelOrDelegate) && LabelOrDelegate.__Class = "Delegate"))
	{
		if(!Hotkeys.HasKey(key))
			Hotkeys[key] := []
		Hotkeys[key][hwnd] := LabelOrDelegate
		Hotkey, If, AssignHotkeyToControl(""`, A_ThisHotkey`, "")
		Hotkey, %key%, HotkeyControlLabel, On
		Hotkey, If
	}
}
#if AssignHotkeyToControl("", A_ThisHotkey, "")
HotkeyControlLabel:
AssignHotkeyToControl()
return
#if